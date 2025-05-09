
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  

  remove_default_node_pool = true
  initial_node_count       = 1
  
 
  logging_service    = "none"
  monitoring_service = "none"
  node_locations     = ["europe-west1-b"]
  

  network    = "default"
  subnetwork = "default"
}

resource "google_container_node_pool" "main_pool" {
  name       = "main-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1  
  
  node_config {
    preemptible  = false
    machine_type = "n2d-standard-2"
    disk_size_gb = 20
 
    labels = {
      nodepool = "main-pool"
    }
    
   
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}


resource "google_container_node_pool" "application_pool" {
  name       = "application-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name


  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  
  node_config {
    preemptible  = false
    machine_type = "n2d-standard-2"
    disk_size_gb = 20
    
    labels = {
      nodepool = "application-pool"
    }
    

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}