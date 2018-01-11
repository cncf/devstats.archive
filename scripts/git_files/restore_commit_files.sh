sudo -u postgres psql gha < gha.sql
sudo -u postgres psql prometheus < prometheus.sql
sudo -u postgres psql opentracing < opentracing.sql
sudo -u postgres psql fluentd < fluentd.sql
sudo -u postgres psql linkerd < linkerd.sql
sudo -u postgres psql grpc < grpc.sql
sudo -u postgres psql coredns < coredns.sql
sudo -u postgres psql containerd < containerd.sql
