module cmd.document;

import std.algorithm;
import std.array;
import std.range;
import std.stdio;
import std.typecons;

import cmd.ansi;

public alias Term = Tuple!(string, string);

public class Section {
    public const string title;
    public const string body;
    protected Term[] _terms;
    protected size_t longest = 0;

    public this(string title, string body = null, Term[] terms = []) @safe {
        assert(title !is null, "Section title cannot be null");
        this.title = title;
        this.body = body;
        _terms = terms;
        longest = !terms.empty() ?terms.map!(t => t[0].stripAnsi().length).maxElement() : 0;
    }

    public const(Term[]) terms() const nothrow @safe {
        return _terms;
    }

    public Section add(Term term) @safe {
        _terms ~= term;
        longest = max(longest, term[0].stripAnsi().length);
        return this;
    }

    public Section add(string term, string definition) @safe {
        return this.add(Term(term, definition));
    }
}

public class Document {
    protected Section[] _sections;

    public this() nothrow @safe {
        _sections = [];
    }

    public const(Section) section(string title) const @safe {
        auto sections = this.sections().find!(s => s.title.stripAnsi() == title.stripAnsi());
        if (sections.empty()) return null;
        return sections.front();
    }

    public const(Section[]) sections() const nothrow @safe {
        return _sections;
    }

    public Document add(Section section) nothrow @safe {
        _sections ~= section;
        return this;
    }

    public Document add(string title, string body = null, Term[] terms = []) @safe {
        return this.add(new Section(title, body, terms));
    }

    public Document add(string section, Term term) @safe {
        auto sections = _sections.find!(s => s.title.stripAnsi() == section.stripAnsi());
        assert(!sections.empty(), "Could not find section " ~ section);
        sections.front().add(term);
        return this;
    }
    
    public Document add(string section, string term, string definition) @safe {
        return this.add(section, Term(term, definition));
    }

    public void print() const @safe {
        const longest = sections().empty() ? 0 : sections().map!(s => s.longest).maxElement();
        
        for (size_t i = 0; i < _sections.length; ++i) {
            const section = _sections[i];
            writeln(section.title);
            if (section.body !is null)
                writeln("  " ~ section.body);
            foreach (term; section.terms()) {
                writeln(
                    "  "
                    ~ term[0]
                    ~ ' '.repeat(max(2, longest - term[0].stripAnsi().length + 2)).array()
                    ~ term[1]
                );
            }
            if (i + 1 < _sections.length)
                writeln();
        }
    }
}
