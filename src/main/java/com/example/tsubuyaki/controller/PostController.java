package com.example.tsubuyaki.controller;

import com.example.tsubuyaki.domain.Post;
import com.example.tsubuyaki.service.PostService;
import com.example.tsubuyaki.web.dto.PostForm;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;

@Controller
public class PostController {

    private static final String POST_FORM_VIEW = "posts/form";
    private static final String POST_DETAIL_VIEW = "posts/detail";
    private static final String SHA_256 = "SHA-256";
    private static final int CLIENT_HASH_LENGTH = 8;

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping({ "/", "/posts" })
    public String list(@RequestParam(name = "q", required = false) String q, Model model) {
        String query = normalizeQuery(q);
        boolean hasQuery = !query.isEmpty();
        List<Post> posts = hasQuery ? postService.searchByBody(query) : postService.findLatest50();
        model.addAttribute("posts", posts);
        model.addAttribute("query", query);
        model.addAttribute("hasQuery", hasQuery);
        return "posts/list";
    }

    @GetMapping("/posts/{id}")
    public String detail(@PathVariable Long id, Model model) {
        model.addAttribute("post", postService.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND)));
        model.addAttribute("likeCount", postService.countLikes(id));
        return POST_DETAIL_VIEW;
    }

    @PostMapping("/posts/{id}/likes")
    public String toggleLike(@PathVariable Long id, HttpServletRequest request) {
        postService.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        postService.toggleLike(id, clientHash(request));
        return "redirect:/posts/" + id;
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

    private String normalizeQuery(String q) {
        if (q == null) {
            return "";
        }
        return q.trim();
    }

    private String clientHash(HttpServletRequest request) {
        String userAgent = Optional.ofNullable(request.getHeader("User-Agent")).orElse("");
        String source = request.getRemoteAddr() + userAgent;
        return HexFormat.of()
                .formatHex(sha256(source))
                .substring(0, CLIENT_HASH_LENGTH);
    }

    private byte[] sha256(String source) {
        try {
            return MessageDigest.getInstance(SHA_256)
                    .digest(source.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 algorithm is not available", e);
        }
    }
}
