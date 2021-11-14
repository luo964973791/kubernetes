```javascript
kubectl create configmap nginx-config --from-file /root/nginx.conf -n nginx-php-fpm
kubectl create configmap php-ini --from-file /root/php.ini -n nginx-php-fpm
```
```javascript
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: nginx-php-fpm
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: richarvey/nginx-php-fpm:1.10.3
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            cpu: "500m"
            memory: 512Mi
          requests:
            cpu: "250m"
            memory: 256Mi
        env:
        - name: TZ
          value: "Asia/Shanghai"
        ports:
        - name: tcp80
          containerPort: 80
        volumeMounts:
          - mountPath: /usr/local/etc/php/php.ini
            name: php-ini
            subPath: php.ini-production
          - name: nginx-config
            mountPath: /etc/nginx/nginx.conf
            subPath: nginx.conf
          - name: html
            mountPath: /var/www/html
      volumes:
      - name: html
        persistentVolumeClaim:
          claimName: csi-cephfs-pvc
      - name: nginx-config
        configMap:
          name: nginx-config
          items:
          - key: nginx.conf
            path: nginx.conf
      - name: php-ini
        configMap:
          name: php-ini
        name: php-ini
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: nginx-php-fpm
  labels:
    app: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 32080
    protocol: TCP
    name: http
  selector:
    app: nginx
```
