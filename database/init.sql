CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC,
    stock INTEGER
);

INSERT INTO products (name, description, price, stock) VALUES
('Laptop', 'Gaming Laptop', 85000, 5),
('Keyboard', 'Mechanical Keyboard', 3500, 20),
('Mouse', 'Wireless Mouse', 1200, 15);
