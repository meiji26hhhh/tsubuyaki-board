package com.example.tsubuyaki.controller;

import com.example.tsubuyaki.service.PostService;
import com.example.tsubuyaki.web.dto.PostForm;
import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;

@Controller
public class PostController {

    private static final String POST_FORM_ATTRIBUTE = "postForm";
    private static final String POST_FORM_VIEW = "posts/form";
    private static final String POSTS_REDIRECT = "redirect:/posts";

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping({ "/", "/posts" })
    public String list(Model model) {
        model.addAttribute("posts", postService.findLatest50());
        return "posts/list";
    }

    @GetMapping("/posts/new")
    public String showNewForm(Model model) {
        model.addAttribute(POST_FORM_ATTRIBUTE, new PostForm());
        return POST_FORM_VIEW;
    }

    @PostMapping("/posts/new")
    public String create(@Valid @ModelAttribute(POST_FORM_ATTRIBUTE) PostForm postForm,
            BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            return POST_FORM_VIEW;
        }
        postService.create(postForm.getAuthor(), postForm.getBody());
        return POSTS_REDIRECT;
    }

    // 演習中に追加するエンドポイント:
    //   @GetMapping("/posts/{id}")       // 詳細
}
