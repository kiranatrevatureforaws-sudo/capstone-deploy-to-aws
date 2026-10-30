package com.rev.app.dto;

import java.math.BigDecimal;

public record ProductRequest(String name, BigDecimal price, String category) {
}
