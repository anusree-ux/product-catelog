from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Product(db.Model):

    __tablename__ = "products"

    id = db.Column(db.Integer, primary_key=True)

    name = db.Column(db.String(100))

    description = db.Column(db.Text)

    price = db.Column(db.Float)

    stock = db.Column(db.Integer)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "price": self.price,
            "stock": self.stock
        }
