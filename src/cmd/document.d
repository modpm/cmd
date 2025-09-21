module cmd.document;

import std.algorithm;
import std.array;
import std.range;
import std.stdio;
import std.typecons;

import cmd.ansi;

/** Represents a term with a definition. */
public alias Term = Tuple!(string, string);

/** Represents a section of a document. */
public class Section {
    /** Title of the section. */
    public const string title;

    /** Main body text of the section, or `null`. */
    public const string body;

    /** Terms and definitions associated with the section. */
    protected Term[] _terms;

    /** The length of the longest term. */
    protected size_t longest = 0;

    /**
     * Constructs a new section.
     *
     * Params:
     *   title = Title of the section.
     *   body = Main body text of the section, or `null`.
     *   terms = Terms and definitions associated with the section.
     * Throws:
     *   AssertionError if the title is null.
     */
    public this(string title, string body = null, Term[] terms = []) @safe {
        assert(title !is null, "Section title cannot be null");
        this.title = title;
        this.body = body;
        _terms = terms;
        longest = !terms.empty() ? terms.map!(t => t[0].stripAnsi().length).maxElement() : 0;
    }

    /** Terms and definitions associated with the section. */
    public const(Term[]) terms() const nothrow @safe {
        return _terms;
    }

    /** Adds a term to the section. */
    public Section add(Term term) @safe {
        _terms ~= term;
        longest = max(longest, term[0].stripAnsi().length);
        return this;
    }

    /**
     * Adds a term to the section.
     *
     * Params:
     *   term = Term text.
     *   definition = Definition text.
     */
    public Section add(string term, string definition) @safe {
        return this.add(Term(term, definition));
    }
}

/**
 * Represents a document comprised of sections.
 */
public class Document {
    /** Sections associated with this document. */
    protected Section[] _sections;

    /** Constructs a new document. */
    public this() nothrow @safe {
        _sections = [];
    }

    /**
     * Gets a section associated with this document by its title (ANSI is stripped).
     *
     * Params:
     *   title = Title of the section.
     * Returns:
     *   Null if no matching section is found, otherwise the matching section.
     */
    public const(Section) section(string title) const @safe {
        auto sections = this.sections().find!(s => s.title.stripAnsi() == title.stripAnsi());
        if (sections.empty()) return null;
        return sections.front();
    }

    /** Gets the sections associated with this document. */
    public const(Section[]) sections() const nothrow @safe {
        return _sections;
    }

    /** Adds a section to this document. */
    public Document add(Section section) nothrow @safe {
        _sections ~= section;
        return this;
    }

    /**
     * Adds a section to this document.
     *
     * Params:
     *   title = Title of the section.
     *   body = Body of the section.
     *   terms = Terms associated with the section.
     */
    public Document add(string title, string body = null, Term[] terms = []) @safe {
        return this.add(new Section(title, body, terms));
    }

    /** Adds a term to a section matching the specified title (ANSI is stripped for matching). */
    public Document add(string section, Term term) @safe {
        auto sections = _sections.find!(s => s.title.stripAnsi() == section.stripAnsi());
        assert(!sections.empty(), "Could not find section " ~ section);
        sections.front().add(term);
        return this;
    }

    /** Adds a term to a section matching the specified title (ANSI is stripped for matching). */
    public Document add(string section, string term, string definition) @safe {
        return this.add(section, Term(term, definition));
    }

    /**
     * Prints this document to standard output.
     */
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
