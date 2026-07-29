package com.inventorymanagement;

import java.sql.Connection;
import java.sql.DriverManager;

public class TestConnection {
    public static void main(String[] args) {
        String[] urls = new String[]{
            "jdbc:postgresql://aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres?sslmode=require",
            "jdbc:postgresql://aws-1-ap-northeast-2.pooler.supabase.com:6543/postgres?sslmode=require",
            "jdbc:postgresql://db.rcdbqpmmtyioqxrzsdeg.supabase.co:5432/postgres?sslmode=require"
        };
        String[] users = new String[]{
            "postgres.rcdbqpmmtyioqxrzsdeg",
            "postgres"
        };
        String pass = "hAOZTxxIfDACay9B";

        for (String url : urls) {
            for (String user : users) {
                System.out.println("Trying URL: " + url + " | USER: " + user);
                try (Connection conn = DriverManager.getConnection(url, user, pass)) {
                    System.out.println(">>> SUCCESS! URL: " + url + " | USER: " + user);
                    return;
                } catch (Exception e) {
                    System.out.println("    FAILED: " + e.getMessage());
                }
            }
        }
    }
}
