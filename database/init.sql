CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price NUMERIC(10,2),
    stock INTEGER
);

INSERT INTO products(name,description,price,stock)
VALUES
('Laptop','Gaming Laptop',85000,5),
('Keyboard','Mechanical Keyboard',3500,20),
('Mouse','Wireless Mouse',1200,15);
