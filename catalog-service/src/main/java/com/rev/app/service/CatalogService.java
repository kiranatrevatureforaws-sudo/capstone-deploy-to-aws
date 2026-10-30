package com.rev.app.service;

import com.rev.app.dto.ProductRequest;
import com.rev.app.model.Product;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.time.Duration;
import java.util.List;

@Service
public class CatalogService {

    private static final String PRODUCTS = "/api/products";
    private final WebClient webClient;
    private final Duration timeout;

    public CatalogService(@Qualifier("productWebClient") WebClient webClient,
            @Value("${product-service.timeout}") Duration timeout) {
        this.webClient = webClient;
        this.timeout = timeout;
    }

    public Mono<List<Product>> findAll() {
        return webClient.get().uri(PRODUCTS).retrieve()
                .bodyToMono(new ParameterizedTypeReference<List<Product>>() { })
                .timeout(timeout);
    }

    public Mono<Product> findById(long id) {
        return webClient.get().uri(PRODUCTS + "/{id}", id).retrieve()
                .bodyToMono(Product.class).timeout(timeout);
    }

    public Mono<Product> create(ProductRequest request) {
        return webClient.post().uri(PRODUCTS).bodyValue(request).retrieve()
                .bodyToMono(Product.class).timeout(timeout);
    }

    public Mono<Product> update(long id, ProductRequest request) {
        return webClient.put().uri(PRODUCTS + "/{id}", id).bodyValue(request).retrieve()
                .bodyToMono(Product.class).timeout(timeout);
    }

    public Mono<Void> delete(long id) {
        return webClient.delete().uri(PRODUCTS + "/{id}", id).retrieve()
                .toBodilessEntity().timeout(timeout).then();
    }
}
