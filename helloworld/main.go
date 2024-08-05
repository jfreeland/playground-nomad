package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	requestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"path"},
	)
	requestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Histogram of response duration for HTTP requests",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"path"},
	)

	isHealthy = true
)

func init() {
	prometheus.MustRegister(requestsTotal)
	prometheus.MustRegister(requestDuration)
}

func main() {
	port := flag.Int("p", 8080, "TCP port to listen on for handling HTTP requests.")
	healthPort := flag.Int("hp", 8081, "TCP port to listen on for health check requests.")
	flag.Parse()

	mux := http.NewServeMux()

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		requestsTotal.WithLabelValues(r.URL.Path).Inc()

		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read request body", http.StatusInternalServerError)
			return
		}

		response := map[string]string{"message": "hello world"}
		jsonResponse, err := json.Marshal(response)
		if err != nil {
			http.Error(w, "Failed to create JSON response", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write(jsonResponse)

		duration := time.Since(start).Seconds()
		requestDuration.WithLabelValues(r.URL.Path).Observe(duration)
		log.Printf("Handled request: read %v bytes in %v seconds", len(body), duration)
	})

	mux.Handle("/metrics", promhttp.Handler())

	appServer := &http.Server{
		Addr:    fmt.Sprintf(":%d", *port),
		Handler: mux,
	}

	healthMux := http.NewServeMux()
	healthMux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		if isHealthy {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("ok"))
		} else {
			w.WriteHeader(http.StatusServiceUnavailable)
			w.Write([]byte("unhealthy"))
		}
	})

	healthServer := &http.Server{
		Addr:    fmt.Sprintf(":%d", *healthPort),
		Handler: healthMux,
	}

	// Channel to listen for interrupt or terminate signals from the OS
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("Starting app server on port %d", *port)
		if err := appServer.ListenAndServe(); err != http.ErrServerClosed {
			log.Fatalf("ListenAndServe(): %v", err)
		}
	}()

	go func() {
		log.Printf("Starting health server on port %d", *healthPort)
		if err := healthServer.ListenAndServe(); err != http.ErrServerClosed {
			log.Fatalf("ListenAndServe(): %v", err)
		}
	}()

	// Wait for a signal
	<-stop

	// Set the service to unhealthy to pull the pod from rotation
	log.Println("Setting service to unhealthy...")
	isHealthy = false

	// Wait for 5 seconds before shutting down the actual server
	log.Println("Waiting for 5 seconds before shutting down...")
	time.Sleep(5 * time.Second)

	// Attempt to gracefully shutdown the app server with a timeout of 5 seconds.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := appServer.Shutdown(ctx); err != nil {
		log.Fatalf("App Server Shutdown Failed:%+v", err)
	}

	// Attempt to gracefully shutdown the health server with a timeout of 5 seconds.
	if err := healthServer.Shutdown(ctx); err != nil {
		log.Fatalf("Health Server Shutdown Failed:%+v", err)
	}

	log.Println("exited gracefully")
}
