package com.rev.app.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.reactive.function.client.WebClientRequestException;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.concurrent.TimeoutException;

@RestControllerAdvice
public class CatalogExceptionHandler {

    @ExceptionHandler(WebClientResponseException.class)
    public ResponseEntity<byte[]> handleResponse(WebClientResponseException exception) {
        ResponseEntity.BodyBuilder response = ResponseEntity.status(exception.getStatusCode());
        if (exception.getHeaders().getContentType() != null) {
            response.contentType(exception.getHeaders().getContentType());
        }
        return response.body(exception.getResponseBodyAsByteArray());
    }

    @ExceptionHandler(WebClientRequestException.class)
    public ProblemDetail handleConnection(WebClientRequestException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_GATEWAY,
                "Unable to connect to product-service");
    }

    @ExceptionHandler(TimeoutException.class)
    public ProblemDetail handleTimeout(TimeoutException exception) {
        return ProblemDetail.forStatusAndDetail(HttpStatus.GATEWAY_TIMEOUT,
                "Product-service did not respond in time");
    }
}
