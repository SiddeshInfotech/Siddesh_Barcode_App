package com.inventorymanagement;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@SpringBootApplication
public class InventoryManagementApplication {

    public static void main(String[] args) {
        loadDotEnv();
        SpringApplication.run(InventoryManagementApplication.class, args);
    }

    private static void loadDotEnv() {
        Path envPath = Paths.get(".env");
        if (!Files.exists(envPath)) {
            envPath = Paths.get("..", ".env");
        }
        if (Files.exists(envPath)) {
            try {
                List<String> lines = Files.readAllLines(envPath);
                for (String line : lines) {
                    line = line.trim();
                    if (line.isEmpty() || line.startsWith("#")) {
                        continue;
                    }
                    int eqIdx = line.indexOf('=');
                    if (eqIdx > 0) {
                        String key = line.substring(0, eqIdx).trim();
                        String value = line.substring(eqIdx + 1).trim();
                        if (value.startsWith("\"") && value.endsWith("\"")) {
                            value = value.substring(1, value.length() - 1);
                        } else if (value.startsWith("'") && value.endsWith("'")) {
                            value = value.substring(1, value.length() - 1);
                        }
                        if (System.getProperty(key) == null && System.getenv(key) == null) {
                            System.setProperty(key, value);
                        }
                    }
                }
                System.out.println("Loaded environment variables from: " + envPath.toAbsolutePath());
            } catch (IOException e) {
                System.err.println("Error reading .env file: " + e.getMessage());
            }
        } else {
            System.out.println("No .env file found at: " + envPath.toAbsolutePath());
        }

        // Detect if the database password is missing or is a placeholder
        String dbPassword = System.getProperty("SUPABASE_DB_PASSWORD");
        if (dbPassword == null) {
            dbPassword = System.getenv("SUPABASE_DB_PASSWORD");
        }
        if (dbPassword == null || dbPassword.trim().isEmpty() || 
            "your_actual_database_password".equalsIgnoreCase(dbPassword.trim()) || 
            "[YOUR-PASSWORD]".equals(dbPassword.trim())) {
            
            System.out.println("====================================================================");
            System.out.println("WARNING: Supabase database password is not configured or is set to a placeholder.");
            System.out.println("Switching automatically to an in-memory H2 database for local development.");
            System.out.println("====================================================================");
            
            System.setProperty("spring.datasource.url", "jdbc:h2:mem:inventorydb;DB_CLOSE_DELAY=-1;MODE=PostgreSQL");
            System.setProperty("spring.datasource.username", "sa");
            System.setProperty("spring.datasource.password", "");
            System.setProperty("spring.datasource.driver-class-name", "org.h2.Driver");
            System.setProperty("spring.jpa.properties.hibernate.dialect", "org.hibernate.dialect.H2Dialect");
        }
    }
}
