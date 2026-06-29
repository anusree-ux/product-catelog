import os

from flask import Flask, jsonify, request
from flask_cors import CORS

from config import Config
from models import db, Product

app = Flask(__name__)
app.config.from_object(Config)

db.init_app(app)

CORS(app)


@app.route("/health")
def health():
    try:
        db.session.execute(db.text("SELECT 1"))
        return jsonify({
            "status": "healthy",
            "database": "connected"
        })
    except Exception:
        return jsonify({
            "status": "unhealthy",
            "database": "disconnected"
        }),500


@app.route("/products")
def products():

    all_products = Product.query.all()

    return jsonify([p.to_dict() for p in all_products])


@app.route("/products",methods=["POST"])
def create_product():

    data=request.json

    product=Product(
        name=data["name"],
        description=data["description"],
        price=data["price"],
        stock=data["stock"]
    )

    db.session.add(product)
    db.session.commit()

    return jsonify(product.to_dict()),201


@app.route("/products/<int:id>",methods=["DELETE"])
def delete_product(id):

    product=Product.query.get_or_404(id)

    db.session.delete(product)
    db.session.commit()

    return "",204


if __name__=="__main__":
    with app.app_context():
        db.create_all()

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=False
    )
