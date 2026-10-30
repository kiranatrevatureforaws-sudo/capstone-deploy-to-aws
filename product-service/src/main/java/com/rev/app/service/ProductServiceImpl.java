package com.rev.app.service;

import com.rev.app.dto.ProductRequest;
import com.rev.app.model.Product;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
public class ProductServiceImpl implements ProductService {

    private final List<Product> products = new ArrayList<>(List.of(
            new Product(1L, "Laptop", new BigDecimal("999.99"), "Electronics"),
            new Product(2L, "Smartphone", new BigDecimal("499.99"), "Electronics"),
            new Product(3L, "Desk Chair", new BigDecimal("149.99"), "Furniture"),
            new Product(4L, "Notebook", new BigDecimal("4.99"), "Stationery")
    ));
    private long nextId = 6;

    @Override
    public synchronized List<Product> findAll() {
        return List.copyOf(products);
    }

    @Override
    public synchronized Product findById(long id) {
        return products.stream()
                .filter(product -> product.id() == id)
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Product not found with id: " + id));
    }

    @Override
    public synchronized Product create(ProductRequest request) {
        Product product = new Product(nextId++, request.name(), request.price(), request.category());
        products.add(product);
        return product;
    }

    @Override
    public synchronized Product update(long id, ProductRequest request) {
        Product existing = findById(id);
        Product updated = new Product(id, request.name(), request.price(), request.category());
        products.set(products.indexOf(existing), updated);
        return updated;
    }

    @Override
    public synchronized void delete(long id) {
        products.remove(findById(id));
    }
}

