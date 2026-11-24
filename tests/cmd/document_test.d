module cmd.document_test;

import core.exception : AssertError;

import fluent.asserts;

import cmd.ansi;
import cmd.document;
import cmd.test_support;

class ProbeSection : Section {
    public this(string title, string content = null, Term[] terms = []) {
        super(title, content, terms);
    }

    public size_t longestTerm() const {
        return longest;
    }
}

unittest {
    expect({ new Section(null); }).to.throwException!AssertError;
    expect({ new Section(""); }).to.not.throwException!AssertError;
}

unittest {
    auto section = new Section("Title");
    expect(section.add(Term("a", "first")) is section).to.equal(true);
    expect(section.add("b", "second") is section).to.equal(true);
    expect(section.terms().length).to.equal(2);
    expect(section.terms()[0][0]).to.equal("a");
    expect(section.terms()[1][0]).to.equal("b");
    expect(section.terms()[1][1]).to.equal("second");
}

unittest {
    expect(new ProbeSection("T").longestTerm()).to.equal(0);
    expect(new ProbeSection("T", null, [Term("ab", "x"), Term("abcd", "y"), Term("abc", "z")]).longestTerm())
        .to.equal(4);
    expect(new ProbeSection("T", null, [Term(bold("abc"), "x")]).longestTerm()).to.equal(3);
}

unittest {
    auto section = new ProbeSection("T");
    section.add("ab", "x");
    expect(section.longestTerm()).to.equal(2);
    section.add("abcdef", "y");
    expect(section.longestTerm()).to.equal(6);
    section.add("a", "z");
    expect(section.longestTerm()).to.equal(6);
    section.add(Term(bold("abcdefgh"), "w"));
    expect(section.longestTerm()).to.equal(8);
    section.add(Term(bold("abcdefghij"), "v"));
    expect(section.longestTerm()).to.equal(10);
    section.add(Term(link("abcdefghijkl", "u"), "t"));
    expect(section.longestTerm()).to.equal(12);
}

unittest {
    auto doc = new Document();
    auto first = new Section("A");
    auto second = new Section("B");
    expect(doc.add(first) is doc).to.equal(true);
    expect(doc.add(second) is doc).to.equal(true);
    expect(doc.sections().length).to.equal(2);
    expect(doc.sections()[0] is first).to.equal(true);
    expect(doc.sections()[1] is second).to.equal(true);
}

unittest {
    auto doc = new Document();
    expect(doc.add("A") is doc).to.equal(true);
    expect(doc.add("B", "body") is doc).to.equal(true);
    expect(doc.add("C", "body", [Term("k", "v")]) is doc).to.equal(true);
    expect(doc.sections().length).to.equal(3);
    expect(doc.sections()[0].title).to.equal("A");
    expect(doc.sections()[0].body).to.beNull;
    expect(doc.sections()[1].title).to.equal("B");
    expect(doc.sections()[1].body).to.equal("body");
    expect(doc.sections()[2].title).to.equal("C");
    expect(doc.sections()[2].terms().length).to.equal(1);
    expect(doc.sections()[2].terms()[0][0]).to.equal("k");
}

unittest {
    auto doc = new Document();
    expect({ doc.add(cast(string) null); }).to.throwException!AssertError;
}

unittest {
    auto doc = new Document();
    auto first = new Section("A");
    doc.add(first);
    doc.add("B");
    expect(doc.section("A") is first).to.equal(true);
    expect(doc.section("B") is null).to.equal(false);
    expect(doc.section("B").title).to.equal("B");
    expect(doc.section("C") is null).to.equal(true);
    expect(doc.section("a") is null).to.equal(true);
}

unittest {
    auto doc = new Document();
    doc.add(bold("Usage:"), "app");
    expect(doc.section("Usage:") is null).to.equal(false);
    expect(doc.section("Usage:").title).to.equal(bold("Usage:"));
    expect(doc.section(bold("Usage:")) is null).to.equal(false);
    expect(doc.section(dim("Usage:")) is null).to.equal(false);
    expect(doc.section("Usage") is null).to.equal(true);
}

unittest {
    auto doc = new Document();
    auto first = new Section("Same");
    auto second = new Section("Same");
    doc.add(first);
    doc.add(second);
    expect(doc.section("Same") is first).to.equal(true);
}

unittest {
    auto doc = new Document();
    doc.add("Options:");
    expect(doc.add("Options:", Term("a", "first")) is doc).to.equal(true);
    expect(doc.add("Options:", "b", "second") is doc).to.equal(true);
    expect(doc.section("Options:").terms().length).to.equal(2);
    expect(doc.section("Options:").terms()[0][0]).to.equal("a");
    expect(doc.section("Options:").terms()[1][0]).to.equal("b");
    expect(doc.section("Options:").terms()[1][1]).to.equal("second");
}

unittest {
    auto doc = new Document();
    doc.add(bold("Options:"));
    doc.add("Options:", "a", "first");
    expect(doc.section("Options:").terms().length).to.equal(1);
}

unittest {
    auto doc = new Document();
    auto first = new Section("Same");
    auto second = new Section("Same");
    doc.add(first);
    doc.add(second);
    doc.add("Same", "a", "first");
    expect(first.terms().length).to.equal(1);
    expect(second.terms().length).to.equal(0);
}

unittest {
    auto doc = new Document();
    doc.add("A");
    expect({ doc.add("Missing", Term("a", "b")); }).to.throwException!AssertError;
    expect({ doc.add("Missing", "a", "b"); }).to.throwException!AssertError;
}

unittest {
    auto doc = new Document();
    expect(captureStdout({ doc.print(); })).to.equal("");
}

unittest {
    auto doc = new Document();
    doc.add("Title");
    expect(captureStdout({ doc.print(); })).to.equal("Title\n");
}

unittest {
    auto doc = new Document();
    doc.add("Description:", "Does things");
    expect(captureStdout({ doc.print(); })).to.equal("Description:\n  Does things\n");
}

unittest {
    auto doc = new Document();
    doc.add("Title", "");
    expect(captureStdout({ doc.print(); })).to.equal("Title\n  \n");
}

unittest {
    auto doc = new Document();
    doc.add("Commands:", null, [Term("run", "Run it"), Term("build", "Build it")]);
    auto expected = "Commands:\n"
        ~ "  run" ~ sp(4) ~ "Run it\n"
        ~ "  build" ~ sp(2) ~ "Build it\n";
    expect(captureStdout({ doc.print(); })).to.equal(expected);
}

unittest {
    auto doc = new Document();
    doc.add("Title", "Body", [Term("a", "x")]);
    expect(captureStdout({ doc.print(); })).to.equal("Title\n  Body\n  a" ~ sp(2) ~ "x\n");
}

unittest {
    auto doc = new Document();
    doc.add("Usage:", "app run");
    doc.add("Commands:", null, [Term("run", "Run it"), Term("build", "Build it")]);
    auto expected = "Usage:\n"
        ~ "  app run\n"
        ~ "\n"
        ~ "Commands:\n"
        ~ "  run" ~ sp(4) ~ "Run it\n"
        ~ "  build" ~ sp(2) ~ "Build it\n";
    expect(captureStdout({ doc.print(); })).to.equal(expected);
}

unittest {
    auto doc = new Document();
    doc.add("A", null, [Term("a", "x")]);
    doc.add("B", null, [Term("longer", "y")]);
    auto expected = "A\n"
        ~ "  a" ~ sp(7) ~ "x\n"
        ~ "\n"
        ~ "B\n"
        ~ "  longer" ~ sp(2) ~ "y\n";
    expect(captureStdout({ doc.print(); })).to.equal(expected);
}

unittest {
    auto doc = new Document();
    doc.add(bold("Opts:"), null, [Term(bold("ab"), "x"), Term("abcd", "y")]);
    auto expected = bold("Opts:") ~ "\n"
        ~ "  " ~ bold("ab") ~ sp(4) ~ "x\n"
        ~ "  abcd" ~ sp(2) ~ "y\n";
    expect(captureStdout({ doc.print(); })).to.equal(expected);
}

unittest {
    auto doc = new Document();
    doc.add("A");
    doc.add("B");
    doc.add("C");
    expect(captureStdout({ doc.print(); })).to.equal("A\n\nB\n\nC\n");
}

unittest {
    auto doc = new Document();
    doc.add("Options:");
    doc.add("Options:", "a", "first");
    doc.add("Options:", "bb", "second");
    auto expected = "Options:\n"
        ~ "  a" ~ sp(3) ~ "first\n"
        ~ "  bb" ~ sp(2) ~ "second\n";
    expect(captureStdout({ doc.print(); })).to.equal(expected);
}

unittest {
    auto doc = new Document();
    doc.add("Title", "Body", [Term("a", "x")]);
    auto once = captureStdout({ doc.print(); });
    auto twice = captureStdout({ doc.print(); });
    expect(once).to.equal(twice);
}
