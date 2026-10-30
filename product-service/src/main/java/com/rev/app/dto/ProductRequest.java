package com.rev.app.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record ProductRequest(
        @NotBlank String name,
        @NotNull @DecimalMin("0.0") BigDecimal price,
        @NotBlank String category) {
}
