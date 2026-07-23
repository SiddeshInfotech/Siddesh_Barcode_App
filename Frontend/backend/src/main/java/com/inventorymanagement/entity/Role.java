package com.inventorymanagement.entity;

import com.inventorymanagement.constants.RoleName;
import jakarta.persistence.*;
import lombok.*;

/**
 * JPA entity representing user authorization roles in the database.
 */
@Entity
@Table(name = "roles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Role {

    /**
     * Unique identifier for the role.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Enumerated name of the role.
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 30, unique = true, nullable = false)
    private RoleName name;
}
