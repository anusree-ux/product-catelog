FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN apt-get update && apt-get install -y curl

# Copy backend code
COPY . .

# Expose Flask port
EXPOSE 5000

# Run app
CMD ["python", "-u", "app.py"]
