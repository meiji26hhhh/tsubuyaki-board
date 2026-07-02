package com.example.tsubuyaki.service;

import com.example.tsubuyaki.domain.Post;
import com.example.tsubuyaki.domain.PostLike;
import com.example.tsubuyaki.repository.PostLikeRepository;
import com.example.tsubuyaki.repository.PostRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class PostServiceTest {

    @Mock
    private PostRepository postRepository;

    @Mock
    private PostLikeRepository postLikeRepository;

    @InjectMocks
    private PostService postService;

    @Test
    @DisplayName("投稿一覧_最新50件取得_Repositoryの結果を返す")
    void 投稿一覧_最新50件取得_Repositoryの結果を返す() {
        List<Post> posts = List.of(
                new Post("alice", "新しい投稿", LocalDateTime.parse("2026-05-23T10:00:00"))
        );
        given(postRepository.findTop50ByOrderByCreatedAtDesc()).willReturn(posts);

        List<Post> actual = postService.findLatest50();

        assertThat(actual).isSameAs(posts);
    }

    @Test
    @DisplayName("投稿検索_本文キーワード指定_Repositoryの検索結果を返す")
    void 投稿検索_本文キーワード指定_Repositoryの検索結果を返す() {
        List<Post> posts = List.of(
                new Post("alice", "Oracle Database を検索する", LocalDateTime.parse("2026-05-23T10:00:00"))
        );
        given(postRepository.findTop50ByBodyContainingOrderByCreatedAtDesc("Oracle")).willReturn(posts);

        List<Post> actual = postService.searchByBody("Oracle");

        assertThat(actual).isSameAs(posts);
    }

    @Test
    @DisplayName("投稿詳細_IDで取得_Repositoryの結果を返す")
    void 投稿詳細_IDで取得_Repositoryの結果を返す() {
        Post post = new Post("alice", "詳細を表示する投稿", LocalDateTime.parse("2026-05-23T10:00:00"));
        given(postRepository.findById(1L)).willReturn(Optional.of(post));

        Optional<Post> actual = postService.findById(1L);

        assertThat(actual).containsSame(post);
    }

    @Test
    @DisplayName("いいね数取得_投稿ID指定_Repositoryの件数を返す")
    void いいね数取得_投稿ID指定_Repositoryの件数を返す() {
        given(postLikeRepository.countByPost_Id(1L)).willReturn(2L);

        long actual = postService.countLikes(1L);

        assertThat(actual).isEqualTo(2L);
    }

    @Test
    @DisplayName("いいねトグル_clientHash未登録_いいねを登録する")
    void いいねトグル_clientHash未登録_いいねを登録する() {
        Post post = new Post("alice", "いいね対象", LocalDateTime.parse("2026-05-23T10:00:00"));
        given(postLikeRepository.existsByPost_IdAndClientHash(1L, "abcd1234")).willReturn(false);
        given(postRepository.findById(1L)).willReturn(Optional.of(post));

        postService.toggleLike(1L, "abcd1234");

        ArgumentCaptor<PostLike> captor = ArgumentCaptor.forClass(PostLike.class);
        verify(postLikeRepository).save(captor.capture());
        assertThat(captor.getValue().getPost()).isSameAs(post);
        assertThat(captor.getValue().getClientHash()).isEqualTo("abcd1234");
    }

    @Test
    @DisplayName("いいねトグル_clientHash登録済み_いいねを削除する")
    void いいねトグル_clientHash登録済み_いいねを削除する() {
        given(postLikeRepository.existsByPost_IdAndClientHash(1L, "abcd1234")).willReturn(true);

        postService.toggleLike(1L, "abcd1234");

        verify(postLikeRepository).deleteByPost_IdAndClientHash(1L, "abcd1234");
        verify(postRepository, never()).findById(1L);
        verify(postLikeRepository, never()).save(any());
    }
}
