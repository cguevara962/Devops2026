using devsecops.demo from '../db/schema';

service CatalogService @(path: '/catalog') {
  @readonly entity Products as projection on demo.Products;
}

annotate CatalogService.Products with @(
  UI.HeaderInfo: {
    TypeName:       'Product',
    TypeNamePlural: 'Products',
    Title:          { Value: name }
  },
  UI.LineItem: [
    { Value: name,        Label: 'Name'     },
    { Value: category,    Label: 'Category' },
    { Value: price,       Label: 'Price'    },
    { Value: stock,       Label: 'Stock'    },
    { Value: active,      Label: 'Active'   }
  ],
  UI.SelectionFields: [ category, active ]
);
