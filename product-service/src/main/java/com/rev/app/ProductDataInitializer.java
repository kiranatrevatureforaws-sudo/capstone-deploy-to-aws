package com.rev.app;

import com.rev.app.model.ProductEntity;
import com.rev.app.service.ProductRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;
import java.util.List;

@Configuration
public class ProductDataInitializer {

    @Bean
    CommandLineRunner initializeProducts(ProductRepository repository) {
        return args -> {
            if (repository.count() == 0) {
                repository.saveAll(List.of(
                        new ProductEntity("Laptop", new BigDecimal("999.99"), "Electronics"),
                        new ProductEntity("Smartphone", new BigDecimal("499.99"), "Electronics"),
                        new ProductEntity("Desk Chair", new BigDecimal("149.99"), "Furniture"),
                        new ProductEntity("Notebook", new BigDecimal("4.99"), "Stationery")
                ));
            }
        };
    }
}
