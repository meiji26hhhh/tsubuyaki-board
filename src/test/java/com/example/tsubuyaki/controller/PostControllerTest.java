package com.example.tsubuyaki.controller;

import com.example.tsubuyaki.domain.Post;
import com.example.tsubuyaki.service.PostService;
import com.example.tsubuyaki.web.dto.PostForm;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.instanceOf;
import static org.mockito.BDDMockito.given;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

@WebMvcTest(PostController.class)
class PostControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PostService postService;

    @Test
    @DisplayName("投稿一覧_GET_posts_Serviceの最新50件をビューに渡す")
    void 投稿一覧_GET_posts_Serviceの最新50件をビューに渡す() throws Exception {
        List<Post> posts = List.of(
                new Post("alice", "新しい投稿", LocalDateTime.parse("2026-05-23T10:00:00")),
                new Post("bob", "古い投稿", LocalDateTime.parse("2026-05-23T09:00:00"))
        );
        given(postService.findLatest50()).willReturn(posts);

        mockMvc.perform(get("/posts"))
                .andExpect(status().isOk())
                .andExpect(view().name("posts/list"))
                .andExpect(model().attribute("posts", posts));
    }

    @Test
    @DisplayName("投稿詳細_GET_posts_id_Serviceの投稿をビューに渡す")
    void 投稿詳細_GET_posts_id_Serviceの投稿をビューに渡す() throws Exception {
        Post post = new Post("alice", "詳細を表示する投稿", LocalDateTime.parse("2026-05-23T10:00:00"));
        given(postService.findById(1L)).willReturn(Optional.of(post));

        mockMvc.perform(get("/posts/1"))
                .andExpect(status().isOk())
                .andExpect(view().name("posts/detail"))
                .andExpect(model().attribute("post", post));
    }

    @Test
    @DisplayName("投稿詳細_GET_posts_id_存在しないidなら404を返す")
    void 投稿詳細_GET_posts_id_存在しないidなら404を返す() throws Exception {
        given(postService.findById(999L)).willReturn(Optional.empty());

        mockMvc.perform(get("/posts/999"))
                .andExpect(status().isNotFound());

        verify(postService).findById(999L);
    }

    @Test
    @DisplayName("新規投稿フォーム_GET_posts_new_PostFormをビューに渡す")
    void 新規投稿フォーム_GET_posts_new_PostFormをビューに渡す() throws Exception {
        mockMvc.perform(get("/posts/new"))
                .andExpect(status().isOk())
                .andExpect(view().name("posts/form"))
                .andExpect(model().attribute("postForm", instanceOf(PostForm.class)))
                .andExpect(content().string(containsString("action=\"/posts\"")));
    }

    @Test
    @DisplayName("新規投稿_POST_posts_入力が空白のみならフォームを再表示しエラーを表示する")
    void 新規投稿_POST_posts_入力が空白のみならフォームを再表示しエラーを表示する() throws Exception {
        mockMvc.perform(post("/posts")
                        .param("author", "   ")
                        .param("body", "   "))
                .andExpect(status().isOk())
                .andExpect(view().name("posts/form"))
                .andExpect(model().attribute("postForm", instanceOf(PostForm.class)))
                .andExpect(model().attributeHasFieldErrors("postForm", "author", "body"))
                .andExpect(content().string(containsString("投稿者名を入力してください")))
                .andExpect(content().string(containsString("本文を入力してください")));

        verify(postService, never()).create(anyString(), anyString());
    }

    @Test
    @DisplayName("新規投稿_POST_posts_入力が上限超過ならフォームを再表示しエラーを表示する")
    void 新規投稿_POST_posts_入力が上限超過ならフォームを再表示しエラーを表示する() throws Exception {
        mockMvc.perform(post("/posts")
                        .param("author", "あ".repeat(31))
                        .param("body", "い".repeat(281)))
                .andExpect(status().isOk())
                .andExpect(view().name("posts/form"))
                .andExpect(model().attribute("postForm", instanceOf(PostForm.class)))
                .andExpect(model().attributeHasFieldErrors("postForm", "author", "body"))
                .andExpect(content().string(containsString("投稿者名は 30 文字以内で入力してください")))
                .andExpect(content().string(containsString("本文は 280 文字以内で入力してください")));

        verify(postService, never()).create(anyString(), anyString());
    }

    @Test
    @DisplayName("新規投稿_POST_posts_Serviceで作成し一覧へリダイレクトする")
    void 新規投稿_POST_posts_Serviceで作成し一覧へリダイレクトする() throws Exception {
        mockMvc.perform(post("/posts")
                        .param("author", "alice")
                        .param("body", "初めての投稿"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/posts"));

        verify(postService).create("alice", "初めての投稿");
    }

    @Test
    @DisplayName("新規投稿_POST_posts_new_Serviceで作成し一覧へリダイレクトする")
    void 新規投稿_POST_posts_new_Serviceで作成し一覧へリダイレクトする() throws Exception {
        mockMvc.perform(post("/posts/new")
                        .param("author", "alice")
                        .param("body", "初めての投稿"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/posts"));

        verify(postService).create("alice", "初めての投稿");
    }
}
