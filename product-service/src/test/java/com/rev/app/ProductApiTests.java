package com.rev.app;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ProductApiTests {

    @LocalServerPort
    private int port;

    private final HttpClient client = HttpClient.newHttpClient();

    @Test
    void crudLifecycleAndValidation() throws Exception {
        String base = "http://localhost:" + port + "/api/products";
        String initialProducts = request("GET", base, null).body();
        assertEquals(4, initialProducts.split("\"id\":", -1).length - 1);
        for (long id = 1; id <= 4; id++) {
            assertEquals(200, request("GET", base + "/" + id, null).statusCode());
        }
        var created = request("POST", base,
                "{\"name\":\"Laptop\",\"price\":999.99,\"category\":\"Electronics\"}");
        assertEquals(201, created.statusCode());
        assertTrue(created.body().contains("\"id\":6"));
        String location = created.headers().firstValue("Location").orElseThrow();

        assertEquals(200, request("GET", location, null).statusCode());
        var listed = request("GET", base, null);
        assertEquals(200, listed.statusCode());
        assertTrue(listed.body().contains("Laptop"));

        var updated = request("PUT", location,
                "{\"name\":\"Monitor\",\"price\":199.99,\"category\":\"Electronics\"}");
        assertEquals(200, updated.statusCode());
        assertTrue(updated.body().contains("Monitor"));
        assertTrue(request("GET", location, null).body().contains("Monitor"));

        assertEquals(400, request("POST", base,
                "{\"name\":\" \",\"price\":-1,\"category\":\"\"}").statusCode());
        assertEquals(400, request("POST", base, "{}").statusCode());
        assertEquals(204, request("DELETE", location, null).statusCode());
        assertEquals(404, request("GET", location, null).statusCode());
        assertEquals(404, request("DELETE", location, null).statusCode());
        assertEquals(404, request("PUT", location,
                "{\"name\":\"Monitor\",\"price\":199.99,\"category\":\"Electronics\"}").statusCode());
        assertEquals(initialProducts, request("GET", base, null).body());
    }

    private HttpResponse<String> request(String method, String url, String body) throws Exception {
        return client.send(HttpRequest.newBuilder(URI.create(url))
                        .header("Content-Type", "application/json")
                        .method(method, body == null ? HttpRequest.BodyPublishers.noBody()
                                : HttpRequest.BodyPublishers.ofString(body))
                        .build(),
                HttpResponse.BodyHandlers.ofString());
    }
}


