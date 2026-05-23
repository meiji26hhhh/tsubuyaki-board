package com.example.butsubutsu.sample;

import com.example.butsubutsu.repository.PostRepository;
import com.example.butsubutsu.service.PostService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Service テストの雛形。TDD の見本として残す (削除禁止)。
 *
 * <p>Mockito で Repository をモック化し、Spring を起動せずにテストする。</p>
 */
@ExtendWith(MockitoExtension.class)
class SamplePostServiceTest {

    @Mock
    private PostRepository postRepository;

    @InjectMocks
    private PostService postService;

    @Test
    @DisplayName("Service_latest_未実装のとき_空リストを返す")
    void latest_returnsEmpty_byDefault() {
        // 現在の PostService.latest() は TODO 状態で空リストを返す。
        // 受講者が実装したら、このテストは別シナリオに置き換える。
        assertThat(postService.latest()).isEmpty();
    }
}
