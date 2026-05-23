package com.example.butsubutsu;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("h2")
class ButsubutsuApplicationTests {

    @Test
    void contextLoads() {
        // Spring コンテキストが h2 プロファイルで起動できることだけを確認する。
    }
}
