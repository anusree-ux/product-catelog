import { useEffect, useState } from "react";
import api from "./api";
import "./App.css";

interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  stock: number;
}

function App() {
  const [products, setProducts] = useState<Product[]>([]);

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [stock, setStock] = useState("");

  const loadProducts = () => {
    api.get("/products").then((res) => setProducts(res.data));
  };

  useEffect(() => {
    loadProducts();
  }, []);

  const addProduct = () => {
    api
      .post("/products", {
        name,
        description,
        price: Number(price),
        stock: Number(stock),
      })
      .then(() => {
        setName("");
        setDescription("");
        setPrice("");
        setStock("");
        loadProducts();
      });
  };

  const deleteProduct = (id: number) => {
    api.delete("/products/" + id).then(() => loadProducts());
  };

  return (
    <div className="container">
      <h2>Product Catalog</h2>

      <input
        placeholder="Name"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />

      <input
        placeholder="Description"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />

      <input
        placeholder="Price"
        value={price}
        onChange={(e) => setPrice(e.target.value)}
      />

      <input
        placeholder="Stock"
        value={stock}
        onChange={(e) => setStock(e.target.value)}
      />

      <button onClick={addProduct}>Add Product</button>

      <br />
      <br />

      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Description</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Action</th>
          </tr>
        </thead>

        <tbody>
          {products.map((product) => (
            <tr key={product.id}>
              <td>{product.id}</td>
              <td>{product.name}</td>
              <td>{product.description}</td>
              <td>{product.price}</td>
              <td>{product.stock}</td>
              <td>
                <button onClick={() => deleteProduct(product.id)}>
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default App;
