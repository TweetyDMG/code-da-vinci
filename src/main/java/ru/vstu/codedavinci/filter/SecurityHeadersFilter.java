package ru.vstu.codedavinci.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * Servlet-фильтр, добавляющий базовые HTTP-заголовки безопасности
 * во все ответы приложения.
 *
 * <ul>
 *   <li>X-Content-Type-Options: nosniff — запрещает MIME-sniffing</li>
 *   <li>X-Frame-Options: DENY — запрещает встраивание в iframe (защита от clickjacking)</li>
 *   <li>X-XSS-Protection: 1; mode=block — включает XSS-фильтр браузера</li>
 *   <li>Referrer-Policy: strict-origin-when-cross-origin — контроль Referer</li>
 * </ul>
 */
@WebFilter("/*")
public class SecurityHeadersFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {

        HttpServletResponse resp = (HttpServletResponse) response;

        resp.setHeader("X-Content-Type-Options", "nosniff");
        resp.setHeader("X-Frame-Options", "DENY");
        resp.setHeader("X-XSS-Protection", "1; mode=block");
        resp.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");

        chain.doFilter(request, response);
    }

    @Override
    public void init(FilterConfig filterConfig) {
        // nothing to init
    }

    @Override
    public void destroy() {
        // nothing to clean up
    }
}
