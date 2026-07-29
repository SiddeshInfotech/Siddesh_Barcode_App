package com.inventorymanagement.service;

import com.inventorymanagement.dto.CreateProductRequest;
import com.inventorymanagement.dto.ProductResponse;
import com.inventorymanagement.dto.UpdateProductRequest;
import com.inventorymanagement.entity.Product;
import com.inventorymanagement.exception.ResourceNotFoundException;
import com.inventorymanagement.repository.ProductRepository;
import com.inventorymanagement.service.impl.ProductServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import java.math.BigDecimal;
import java.util.Collections;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ProductServiceImplTest {

    @Mock
    private ProductRepository productRepository;

    @Mock
    private com.inventorymanagement.repository.ProductBarcodeRepository productBarcodeRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    private Product product;
    private CreateProductRequest createRequest;
    private UpdateProductRequest updateRequest;

    @BeforeEach
    public void setUp() {
        product = Product.builder()
                .id(1L)
                .name("Test Product")
                .description("Test Description")
                .barcode("1234567890")
                .price(new BigDecimal("99.99"))
                .quantity(50)
                .sku("SKU123")
                .category("Electronics")
                .build();

        createRequest = CreateProductRequest.builder()
                .name("Test Product")
                .description("Test Description")
                .barcode("1234567890")
                .price(new BigDecimal("99.99"))
                .quantity(50)
                .sku("SKU123")
                .category("Electronics")
                .build();

        updateRequest = UpdateProductRequest.builder()
                .name("Updated Product")
                .description("Updated Description")
                .barcode("0987654321")
                .price(new BigDecimal("129.99"))
                .quantity(30)
                .sku("SKU987")
                .category("Gadgets")
                .build();
    }

    @Test
    public void testCreateProduct_Success() {
        when(productRepository.existsByName(anyString())).thenReturn(false);
        when(productRepository.existsByBarcode(anyString())).thenReturn(false);
        when(productRepository.existsBySku(anyString())).thenReturn(false);
        when(productRepository.save(any(Product.class))).thenReturn(product);

        ProductResponse response = productService.createProduct(createRequest);

        assertNotNull(response);
        assertEquals(product.getName(), response.getName());
        assertEquals(product.getBarcode(), response.getBarcode());
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    public void testCreateProduct_DuplicateName_ThrowsException() {
        when(productRepository.existsByName(anyString())).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> productService.createProduct(createRequest));
        verify(productRepository, never()).save(any(Product.class));
    }

    @Test
    public void testCreateProduct_DuplicateBarcode_ThrowsException() {
        when(productRepository.existsByName(anyString())).thenReturn(false);
        when(productRepository.existsByBarcode(anyString())).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> productService.createProduct(createRequest));
        verify(productRepository, never()).save(any(Product.class));
    }

    @Test
    public void testCreateProduct_DuplicateSku_ThrowsException() {
        when(productRepository.existsByName(anyString())).thenReturn(false);
        when(productRepository.existsByBarcode(anyString())).thenReturn(false);
        when(productRepository.existsBySku(anyString())).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> productService.createProduct(createRequest));
        verify(productRepository, never()).save(any(Product.class));
    }

    @Test
    public void testUpdateProduct_Success() {
        when(productRepository.findById(anyLong())).thenReturn(Optional.of(product));
        when(productRepository.existsByNameAndIdNot(anyString(), anyLong())).thenReturn(false);
        when(productRepository.existsByBarcodeAndIdNot(anyString(), anyLong())).thenReturn(false);
        when(productRepository.existsBySkuAndIdNot(anyString(), anyLong())).thenReturn(false);
        when(productRepository.save(any(Product.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ProductResponse response = productService.updateProduct(1L, updateRequest);

        assertNotNull(response);
        assertEquals(updateRequest.getName(), response.getName());
        assertEquals(updateRequest.getBarcode(), response.getBarcode());
    }

    @Test
    public void testGetProductById_Success() {
        when(productRepository.findById(anyLong())).thenReturn(Optional.of(product));

        ProductResponse response = productService.getProductById(1L);

        assertNotNull(response);
        assertEquals(product.getId(), response.getId());
    }

    @Test
    public void testGetProductById_NotFound_ThrowsException() {
        when(productRepository.findById(anyLong())).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> productService.getProductById(1L));
    }

    @Test
    public void testGetProductByBarcode_Success() {
        when(productRepository.findByBarcodeIgnoreCase(anyString())).thenReturn(Optional.of(product));

        ProductResponse response = productService.getProductByBarcode("1234567890");

        assertNotNull(response);
        assertEquals(product.getBarcode(), response.getBarcode());
    }

    @Test
    public void testGetProductByBarcode_NotFound_AutoCreatesProduct() {
        when(productRepository.findByBarcodeIgnoreCase(anyString())).thenReturn(Optional.empty());
        when(productBarcodeRepository.findByCodeIgnoreCase(anyString())).thenReturn(Optional.empty());
        when(productRepository.save(any(Product.class))).thenReturn(product);

        ProductResponse response = productService.getProductByBarcode("1234567890");
        assertNotNull(response);
    }

    @Test
    public void testGetAllProducts() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<Product> page = new PageImpl<>(Collections.singletonList(product));
        when(productRepository.findAll(any(Pageable.class))).thenReturn(page);

        Page<ProductResponse> responsePage = productService.getAllProducts(pageable);

        assertNotNull(responsePage);
        assertEquals(1, responsePage.getTotalElements());
        assertEquals(product.getName(), responsePage.getContent().get(0).getName());
    }

    @Test
    public void testDeleteProduct_Success() {
        when(productRepository.findById(anyLong())).thenReturn(Optional.of(product));
        doNothing().when(productRepository).delete(any(Product.class));

        assertDoesNotThrow(() -> productService.deleteProduct(1L));
        verify(productRepository, times(1)).delete(any(Product.class));
    }
}
