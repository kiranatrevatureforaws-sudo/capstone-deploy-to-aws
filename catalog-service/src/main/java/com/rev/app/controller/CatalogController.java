package com.rev.app.controller;

import com.rev.app.dto.ProductRequest;
import com.rev.app.model.Product;
import com.rev.app.service.CatalogService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/catalog/products")
public class CatalogController {

    private final CatalogService catalogService;

    public CatalogController(CatalogService catalogService) {
        this.catalogService = catalogService;
    }

    @GetMapping
    public Mono<List<Product>> findAll() {
        return catalogService.findAll();
    }

    @GetMapping("/{id}")
    public Mono<Product> findById(@PathVariable long id) {
        return catalogService.findById(id);
    }

    @PostMapping
    public Mono<ResponseEntity<Product>> create(@RequestBody ProductRequest request) {
        URI collectionUri = ServletUriComponentsBuilder.fromCurrentRequest().build().toUri();
        return catalogService.create(request).map(product -> ResponseEntity
                .created(URI.create(collectionUri + "/" + product.id())).body(product));
    }

    @PutMapping("/{id}")
    public Mono<Product> update(@PathVariable long id, @RequestBody ProductRequest request) {
        return catalogService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public Mono<ResponseEntity<Void>> delete(@PathVariable long id) {
        return catalogService.delete(id).thenReturn(ResponseEntity.noContent().build());
    }
}
