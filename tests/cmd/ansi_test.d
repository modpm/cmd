module cmd.ansi_test;

import fluent.asserts;

import cmd.ansi;

unittest {
    expect(stripAnsi("")).to.equal("");
    expect(stripAnsi("plain text")).to.equal("plain text");
    expect(stripAnsi("line one\nline two\n")).to.equal("line one\nline two\n");
    expect(stripAnsi("héllo wörld 日本語")).to.equal("héllo wörld 日本語");
}

unittest {
    expect(stripAnsi(bold("x"))).to.equal("x");
    expect(stripAnsi(dim("x"))).to.equal("x");
    expect(stripAnsi(brightBlack("x"))).to.equal("x");
    expect(stripAnsi(bold(dim(brightBlack("x"))))).to.equal("x");
    expect(stripAnsi("a" ~ bold("b") ~ "c" ~ dim("d") ~ "e")).to.equal("abcde");
    expect(stripAnsi(bold("héllo"))).to.equal("héllo");
}

unittest {
    expect(stripAnsi("\x1B[1;31mred\x1B[0m")).to.equal("red");
    expect(stripAnsi("\x1B[38;5;200mpink\x1B[0m")).to.equal("pink");
    expect(stripAnsi("\x1B[38:2:255:0:0mred\x1B[0m")).to.equal("red");
    expect(stripAnsi("\x1B[mx")).to.equal("x");
    expect(stripAnsi("\x1B[31munterminated")).to.equal("unterminated");
}

unittest {
    expect(stripAnsi("\x1B[2Jx\x1B[H")).to.equal("x");
    expect(stripAnsi("\x1B[?25lx\x1B[?25h")).to.equal("x");
    expect(stripAnsi("\x1B[10;20Hx")).to.equal("x");
}

unittest {
    expect(stripAnsi(link("docs", "https://example.com"))).to.equal("docs");
    expect(stripAnsi("see " ~ link("docs", "https://example.com") ~ " now")).to.equal("see docs now");
    expect(stripAnsi(link("a", "1") ~ " " ~ link("b", "2"))).to.equal("a b");
    expect(stripAnsi(link("a\nb", "u"))).to.equal("a\nb");
    expect(stripAnsi(link("", "u"))).to.equal("");
    expect(stripAnsi(link("t", ""))).to.equal("t");
}

unittest {
    expect(stripAnsi("a\x1BOPb")).to.equal("ab");
    expect(stripAnsi("x\x1Bcy")).to.equal("xy");
    expect(stripAnsi("abc\x1B")).to.equal("abc\x1B");
}

unittest {
    auto text = "Usage: " ~ bold("app") ~ " " ~ link("docs", "https://example.com") ~ dim("!");
    expect(stripAnsi(text)).to.equal("Usage: app docs!");
    expect(stripAnsi(stripAnsi(text))).to.equal(stripAnsi(text));
}
