package com.rev.app.service;

import com.rev.app.dto.ProductRequest;
import com.rev.app.model.Product;
import com.rev.app.model.ProductEntity;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;

    public ProductServiceImpl(ProductRepository productRepository) {
        this.productRepository = productRepository;
    }

    @Override
    public List<Product> findAll() {
        return productRepository.findAll().stream().map(this::toProduct).toList();
    }

    @Override
    public Product findById(long id) {
        return productRepository.findById(id)
                .map(this::toProduct)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Product not found with id: " + id));
    }

    @Override
    public Product create(ProductRequest request) {
        return toProduct(productRepository.save(new ProductEntity(
                request.name(), request.price(), request.category())));
    }

    @Override
    public Product update(long id, ProductRequest request) {
        ProductEntity existing = productRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Product not found with id: " + id));
        existing.setName(request.name());
        existing.setPrice(request.price());
        existing.setCategory(request.category());
        return toProduct(productRepository.save(existing));
    }

    @Override
    public void delete(long id) {
        if (!productRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found with id: " + id);
        }
        productRepository.deleteById(id);
    }

    private Product toProduct(ProductEntity entity) {
        return new Product(entity.getId(), entity.getName(), entity.getPrice(), entity.getCategory());
    }
}
