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

    private static final String POST_FORM_VIEW = "posts/form";

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
        return prepareNewForm(model);
    }

    @PostMapping({ "/posts/new", "/posts" })
    public String create(@Valid @ModelAttribute("postForm") PostForm postForm,
            BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            return POST_FORM_VIEW;
        }
        postService.create(postForm.getAuthor(), postForm.getBody());
        return "redirect:/posts";
    }

    private String prepareNewForm(Model model) {
        model.addAttribute("postForm", new PostForm());
        return POST_FORM_VIEW;
    }

    // 演習中に追加するエンドポイント:
    //   @GetMapping("/posts/{id}")       // 詳細
}
