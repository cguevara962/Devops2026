namespace devsecops.demo;

entity Products {
  key ID          : UUID;
      name        : String(100) @mandatory;
      description : String(500);
      category    : String(50);
      price       : Decimal(10, 2);
      stock       : Integer default 0;
      active      : Boolean  default true;
}
