package com.rev.app.service;

import com.rev.app.dto.ProductRequest;
import com.rev.app.model.Product;

import java.util.List;

public interface ProductService {

    List<Product> findAll();

    Product findById(long id);

    Product create(ProductRequest request);

    Product update(long id, ProductRequest request);

    void delete(long id);
}
