module cmd.ansi_test;

import cmd.ansi;

unittest {
    assert(stripAnsi("") == "");
    assert(stripAnsi("plain text") == "plain text");
    assert(stripAnsi("line one\nline two\n") == "line one\nline two\n");
    assert(stripAnsi("héllo wörld 日本語") == "héllo wörld 日本語");
}

unittest {
    assert(stripAnsi(bold("x")) == "x");
    assert(stripAnsi(dim("x")) == "x");
    assert(stripAnsi(brightBlack("x")) == "x");
    assert(stripAnsi(bold(dim(brightBlack("x")))) == "x");
    assert(stripAnsi("a" ~ bold("b") ~ "c" ~ dim("d") ~ "e") == "abcde");
    assert(stripAnsi(bold("héllo")) == "héllo");
}

unittest {
    assert(stripAnsi("\x1B[1;31mred\x1B[0m") == "red");
    assert(stripAnsi("\x1B[38;5;200mpink\x1B[0m") == "pink");
    assert(stripAnsi("\x1B[38:2:255:0:0mred\x1B[0m") == "red");
    assert(stripAnsi("\x1B[mx") == "x");
    assert(stripAnsi("\x1B[31munterminated") == "unterminated");
}

unittest {
    assert(stripAnsi("\x1B[2Jx\x1B[H") == "x");
    assert(stripAnsi("\x1B[?25lx\x1B[?25h") == "x");
    assert(stripAnsi("\x1B[10;20Hx") == "x");
}

unittest {
    assert(stripAnsi(link("docs", "https://example.com")) == "docs");
    assert(stripAnsi("see " ~ link("docs", "https://example.com") ~ " now") == "see docs now");
    assert(stripAnsi(link("a", "1") ~ " " ~ link("b", "2")) == "a b");
    assert(stripAnsi(link("a\nb", "u")) == "a\nb");
    assert(stripAnsi(link("", "u")) == "");
    assert(stripAnsi(link("t", "")) == "t");
}

unittest {
    assert(stripAnsi("a\x1BOPb") == "ab");
    assert(stripAnsi("x\x1Bcy") == "xy");
    assert(stripAnsi("abc\x1B") == "abc\x1B");
}

unittest {
    auto text = "Usage: " ~ bold("app") ~ " " ~ link("docs", "https://example.com") ~ dim("!");
    assert(stripAnsi(text) == "Usage: app docs!");
    assert(stripAnsi(stripAnsi(text)) == stripAnsi(text));
}
