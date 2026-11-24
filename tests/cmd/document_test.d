module cmd.document_test;

import core.exception : AssertError;
import std.exception : assertNotThrown, assertThrown;

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
    assertThrown!AssertError(new Section(null));
    assertNotThrown!AssertError(new Section(""));
}

unittest {
    auto section = new Section("Title");
    assert(section.add(Term("a", "first")) is section);
    assert(section.add("b", "second") is section);
    assert(section.terms().length == 2);
    assert(section.terms()[0][0] == "a");
    assert(section.terms()[1][0] == "b");
    assert(section.terms()[1][1] == "second");
}

unittest {
    assert(new ProbeSection("T").longestTerm() == 0);
    assert(new ProbeSection("T", null, [Term("ab", "x"), Term("abcd", "y"), Term("abc", "z")]).longestTerm() == 4);
    assert(new ProbeSection("T", null, [Term(bold("abc"), "x")]).longestTerm() == 3);
}

unittest {
    auto section = new ProbeSection("T");
    section.add("ab", "x");
    assert(section.longestTerm() == 2);
    section.add("abcdef", "y");
    assert(section.longestTerm() == 6);
    section.add("a", "z");
    assert(section.longestTerm() == 6);
    section.add(Term(bold("abcdefgh"), "w"));
    assert(section.longestTerm() == 8);
    section.add(Term(bold("abcdefghij"), "v"));
    assert(section.longestTerm() == 10);
    section.add(Term(link("abcdefghijkl", "u"), "t"));
    assert(section.longestTerm() == 12);
}

unittest {
    auto doc = new Document();
    auto first = new Section("A");
    auto second = new Section("B");
    assert(doc.add(first) is doc);
    assert(doc.add(second) is doc);
    assert(doc.sections().length == 2);
    assert(doc.sections()[0] is first);
    assert(doc.sections()[1] is second);
}

unittest {
    auto doc = new Document();
    assert(doc.add("A") is doc);
    assert(doc.add("B", "body") is doc);
    assert(doc.add("C", "body", [Term("k", "v")]) is doc);
    assert(doc.sections().length == 3);
    assert(doc.sections()[0].title == "A");
    assert(doc.sections()[0].body is null);
    assert(doc.sections()[1].title == "B");
    assert(doc.sections()[1].body == "body");
    assert(doc.sections()[2].title == "C");
    assert(doc.sections()[2].terms().length == 1);
    assert(doc.sections()[2].terms()[0][0] == "k");
}

unittest {
    auto doc = new Document();
    assertThrown!AssertError(doc.add(cast(string) null));
}

unittest {
    auto doc = new Document();
    auto first = new Section("A");
    doc.add(first);
    doc.add("B");
    assert(doc.section("A") is first);
    assert(doc.section("B") !is null);
    assert(doc.section("B").title == "B");
    assert(doc.section("C") is null);
    assert(doc.section("a") is null);
}

unittest {
    auto doc = new Document();
    doc.add(bold("Usage:"), "app");
    assert(doc.section("Usage:") !is null);
    assert(doc.section("Usage:").title == bold("Usage:"));
    assert(doc.section(bold("Usage:")) !is null);
    assert(doc.section(dim("Usage:")) !is null);
    assert(doc.section("Usage") is null);
}

unittest {
    auto doc = new Document();
    auto first = new Section("Same");
    auto second = new Section("Same");
    doc.add(first);
    doc.add(second);
    assert(doc.section("Same") is first);
}

unittest {
    auto doc = new Document();
    doc.add("Options:");
    assert(doc.add("Options:", Term("a", "first")) is doc);
    assert(doc.add("Options:", "b", "second") is doc);
    assert(doc.section("Options:").terms().length == 2);
    assert(doc.section("Options:").terms()[0][0] == "a");
    assert(doc.section("Options:").terms()[1][0] == "b");
    assert(doc.section("Options:").terms()[1][1] == "second");
}

unittest {
    auto doc = new Document();
    doc.add(bold("Options:"));
    doc.add("Options:", "a", "first");
    assert(doc.section("Options:").terms().length == 1);
}

unittest {
    auto doc = new Document();
    auto first = new Section("Same");
    auto second = new Section("Same");
    doc.add(first);
    doc.add(second);
    doc.add("Same", "a", "first");
    assert(first.terms().length == 1);
    assert(second.terms().length == 0);
}

unittest {
    auto doc = new Document();
    doc.add("A");
    assertThrown!AssertError(doc.add("Missing", Term("a", "b")));
    assertThrown!AssertError(doc.add("Missing", "a", "b"));
}

unittest {
    auto doc = new Document();
    assert(captureStdout({ doc.print(); }) == "");
}

unittest {
    auto doc = new Document();
    doc.add("Title");
    assert(captureStdout({ doc.print(); }) == "Title\n");
}

unittest {
    auto doc = new Document();
    doc.add("Description:", "Does things");
    assert(captureStdout({ doc.print(); }) == "Description:\n  Does things\n");
}

unittest {
    auto doc = new Document();
    doc.add("Title", "");
    assert(captureStdout({ doc.print(); }) == "Title\n  \n");
}

unittest {
    auto doc = new Document();
    doc.add("Commands:", null, [Term("run", "Run it"), Term("build", "Build it")]);
    auto expected = "Commands:\n"
        ~ "  run" ~ sp(4) ~ "Run it\n"
        ~ "  build" ~ sp(2) ~ "Build it\n";
    assert(captureStdout({ doc.print(); }) == expected);
}

unittest {
    auto doc = new Document();
    doc.add("Title", "Body", [Term("a", "x")]);
    assert(captureStdout({ doc.print(); }) == "Title\n  Body\n  a" ~ sp(2) ~ "x\n");
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
    assert(captureStdout({ doc.print(); }) == expected);
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
    assert(captureStdout({ doc.print(); }) == expected);
}

unittest {
    auto doc = new Document();
    doc.add(bold("Opts:"), null, [Term(bold("ab"), "x"), Term("abcd", "y")]);
    auto expected = bold("Opts:") ~ "\n"
        ~ "  " ~ bold("ab") ~ sp(4) ~ "x\n"
        ~ "  abcd" ~ sp(2) ~ "y\n";
    assert(captureStdout({ doc.print(); }) == expected);
}

unittest {
    auto doc = new Document();
    doc.add("A");
    doc.add("B");
    doc.add("C");
    assert(captureStdout({ doc.print(); }) == "A\n\nB\n\nC\n");
}

unittest {
    auto doc = new Document();
    doc.add("Options:");
    doc.add("Options:", "a", "first");
    doc.add("Options:", "bb", "second");
    auto expected = "Options:\n"
        ~ "  a" ~ sp(3) ~ "first\n"
        ~ "  bb" ~ sp(2) ~ "second\n";
    assert(captureStdout({ doc.print(); }) == expected);
}

unittest {
    auto doc = new Document();
    doc.add("Title", "Body", [Term("a", "x")]);
    auto once = captureStdout({ doc.print(); });
    auto twice = captureStdout({ doc.print(); });
    assert(once == twice);
}
