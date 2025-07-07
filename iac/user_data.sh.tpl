#!/bin/bash
yum update -y
yum install -y nginx postgresql15

# ── Nginx shows a page
echo "<h1>BlogoSphere on AWS</h1><p>DB endpoint: ${db_endpoint}</p>" > /usr/share/nginx/html/index.html
systemctl enable nginx
systemctl start nginx

# ── seed Postgres (retry until it answers)
for i in {1..30}; do
  PGPASSWORD="${db_pass}" psql -h ${db_endpoint} -U ${db_user} -d blogodb -c "\q" 2>/dev/null && break
  sleep 10
done

PGPASSWORD="${db_pass}" psql -h ${db_endpoint} -U ${db_user} -d blogodb <<'SQL'
${seed_sql}
SQL
