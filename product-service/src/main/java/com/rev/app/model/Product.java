package com.rev.app.model;

import java.math.BigDecimal;

public record Product(Long id, String name, BigDecimal price, String category) {
}
