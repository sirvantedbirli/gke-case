# GKE Microservices Project

Bu proje, Google Kubernetes Engine (GKE) üzerinde microservices mimarisi kullanarak Kubernetes, Prometheus, Grafana, KEDA ve Istio ile bir uygulama altyapısı kurulumunu içerir.

## Proje Yapısı

Proje, aşağıdaki temel bileşenlerden oluşmaktadır:

- Terraform ile GKE Cluster Kurulumu
- Node Pool Yapılandırması
- Örnek Uygulama Deployment
- Prometheus ve Grafana ile İzleme
- HPA (Horizontal Pod Autoscaler) Yapılandırması
- KEDA (Kubernetes Event-driven Autoscaling) Kurulumu
- Istio Service Mesh Kurulumu

## Gereksinimler

- Google Cloud Platform Hesabı
- Terraform CLI (v1.0+)
- kubectl CLI
- Helm CLI
- istioctl CLI

## Kurulum Adımları

### 1. GKE Cluster Kurulumu

Proje, Terraform kullanılarak europe-west1 bölgesinde özel bir GKE cluster oluşturur. Cluster'ın logging ve monitoring özellikleri devre dışı bırakılmıştır.

```bash
# Terraform başlatma
terraform init

# Terraform plan
terraform plan

# Terraform uygulama
terraform apply
```

Terraform yapılandırması aşağıdaki özelliklere sahip bir GKE cluster oluşturur:

- **Region**: europe-west1
- **Logging/Monitoring**: Devre dışı
- **Node Pools**: 
  - `main-pool`: n2d makine tipi, autoscaling devre dışı
  - `application-pool`: n2d makine tipi, 1-3 node arası autoscaling aktif

### 2. Örnek Uygulama Deploymentı

Örnek uygulama, `sample-app.yaml` manifest dosyası kullanılarak cluster'a deploy edilmiştir. Bu uygulama, `nodeSelector` özelliği kullanılarak sadece `application-pool` üzerinde çalışacak şekilde yapılandırılmıştır.

```bash
kubectl apply -f sample-app.yaml
```

### 3. Horizontal Pod Autoscaler (HPA) Kurulumu

Uygulama, CPU kullanımı %25'in üzerine çıktığında 1-3 pod arasında otomatik ölçeklendirme yapacak şekilde yapılandırılmıştır.

```bash
kubectl apply -f sample-hpa.yaml
```

### 4. Prometheus ve Grafana Kurulumu

Prometheus ve Grafana, Helm kullanılarak cluster üzerine kurulmuştur. Bu araçlar Kubernetes metriklerini izlemek ve görselleştirmek için kullanılmaktadır.

```bash
# Prometheus ve Grafana kurulumu için namespace oluşturma
kubectl create namespace monitoring

# Prometheus Community Helm repo ekleme
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Prometheus ve Grafana kurulumu
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
```

### 5. Pod Restart Alarmı

Grafana üzerinde, pod'ların yeniden başlatılması durumunda uyarı veren bir alarm yapılandırılmıştır.

```bash
# Grafana'ya erişim için port-forwarding
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
```

Grafana arayüzünde oluşturulan alarm, aşağıdaki Prometheus sorgusu ile pod restart olaylarını izler:

```
sum(increase(kube_pod_container_status_restarts_total[15m])) by (pod, namespace) > 0
```

### 6. KEDA Kurulumu (Opsiyonel)

Kubernetes Event-driven Autoscaling (KEDA), HPA'ya alternatif olarak kurulmuş ve yapılandırılmıştır.

```bash
# KEDA namespace oluşturma
kubectl create namespace keda

# KEDA Helm repo ekleme
helm repo add kedacore https://kedacore.github.io/charts
helm repo update

# KEDA kurulumu
helm install keda kedacore/keda --namespace keda
```

KEDA ile ölçeklendirme için `keda-scaledobject.yaml` dosyası uygulanmıştır:

```bash
kubectl apply -f keda-scaledobject.yaml
```

### 7. Istio Kurulumu (Opsiyonel)

Istio service mesh, aşağıdaki bileşenlerle birlikte kurulmuştur:
- istiod (control plane)
- istio-ingressgateway
- istio-egressgateway

```bash
# Istio kurulumu
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Demo profiliyle Istio kurulumu
istioctl install --set profile=demo -y

# Namespace'lere Istio injection etiketi ekleme
kubectl label namespace sample-app istio-injection=enabled
kubectl label namespace monitoring istio-injection=enabled
```

Istio Gateway ve VirtualService yapılandırmaları da uygulanmıştır:

```bash
kubectl apply -f cluster-gateway.yaml
kubectl apply -f sample-app-vs.yaml
kubectl apply -f grafana-vs.yaml
kubectl apply -f prometheus-vs.yaml
```

## Erişim Bilgileri
Bu uygulamalara erişeibilmek için local bilgisayarınızda /etc/hosts dosyasının içerisine istio ingress-gateway loadbalancer external ip bilgisinin karşısına aşağıdaki domainleri girmelisiniz.
### Prometheus ve Grafana

- **Prometheus**: http://sirvanpromet.com
- **Grafana**: http://sirvangrafana.com
  - Kullanıcı adı: admin
  - Şifre: prom-operator (veya kubectl komutunu kullanarak alın: `kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`)

### Örnek Uygulama

- **URL**: http://sirvan.com

## Test Etme

### HPA Test Etme

CPU yükü oluşturarak HPA'nın ölçeklendirme yapmasını test edebilirsiniz:

```bash
# CPU yükü oluşturacak bir pod oluşturma
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://sample-app-service; done"
```

### KEDA Test Etme

KEDA ScaledObject'in çalıştığını doğrulamak için CPU yükü oluşturabilir ve ölçeklendirme davranışını izleyebilirsiniz:

```bash
# KEDA HPA durumunu izleme
kubectl get hpa -n sample-app -w
```

## Temizlik

Proje kaynaklarını temizlemek için:

```bash
# Terraform ile oluşturulan kaynakları silme
terraform destroy
```

## Kaynaklar

- [Terraform GKE Dökümanı](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster)
- [Kubernetes HPA Dökümanı](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Prometheus Operatör Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [KEDA Dökümanı](https://keda.sh/docs/2.10/)
- [Istio Dökümanı](https://istio.io/latest/docs/)
