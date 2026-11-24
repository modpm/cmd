module cmd.flag_test;

import core.exception : AssertError;
import std.exception : assertThrown;

import cmd.flag;

unittest {
    assertThrown!AssertError(new Flag(null, null, "d"));
    assertThrown!AssertError(new Flag("ab", "verbose", "d"));
    assertThrown!AssertError(new Flag("", "verbose", "d"));
    assertThrown!AssertError(new Flag("v", "", "d"));
    assertThrown!AssertError(new Flag(null, "", "d"));
}

unittest {
    auto flag = Flag.fromString("-v, --verbose", "Verbose output");
    assert(flag.shortName == "v");
    assert(flag.longName == "verbose");
    assert(flag.description == "Verbose output");
}

unittest {
    auto onlyLong = Flag.fromString("--verbose", "d");
    assert(onlyLong.shortName is null);
    assert(onlyLong.longName == "verbose");

    auto onlyShort = Flag.fromString("-v", "d");
    assert(onlyShort.shortName == "v");
    assert(onlyShort.longName is null);
}

unittest {
    foreach (format; ["--verbose, -v", "-v,--verbose", "  -v ,  --verbose  ", "  --verbose,-v  "]) {
        auto flag = Flag.fromString(format, "d");
        assert(flag.shortName == "v");
        assert(flag.longName == "verbose");
    }
}

unittest {
    assertThrown!AssertError(Flag.fromString("-a, -b, --c", "d"));
    assertThrown!AssertError(Flag.fromString("-a,-b,-c,-d", "d"));
}

unittest {
    auto both = new Flag("v", "verbose", "d");
    assert(both.formattedName() == "-v, --verbose");
    assert(both.formattedName(true) == "-v, --verbose");
    assert(both.formattedName(false) == "-v, --verbose");
}

unittest {
    auto onlyShort = new Flag("v", null, "d");
    assert(onlyShort.formattedName() == "-v");
    assert(onlyShort.formattedName(true) == "-v");
}

unittest {
    auto onlyLong = new Flag(null, "verbose", "d");
    assert(onlyLong.formattedName() == "--verbose");
    assert(onlyLong.formattedName(false) == "--verbose");
    assert(onlyLong.formattedName(true) == "    --verbose");
}

unittest {
    auto flag = new Flag("v", "verbose", "d");
    assert(flag.matches("--verbose"));
    assert(flag.matches("-v"));
    assert(flag.matches("verbose"));
    assert(flag.matches("v"));
}

unittest {
    auto flag = new Flag("v", "verbose", "d");
    assert(!flag.matches("--v"));
    assert(!flag.matches("-verbose"));
    assert(!flag.matches("--x"));
    assert(!flag.matches("-x"));
    assert(!flag.matches("x"));
    assert(!flag.matches("--"));
    assert(!flag.matches("-"));
    assert(!flag.matches(""));
    assert(!flag.matches(null));
}

unittest {
    auto onlyLong = new Flag(null, "verbose", "d");
    assert(onlyLong.matches("--verbose"));
    assert(onlyLong.matches("verbose"));
    assert(!onlyLong.matches("-v"));
    assert(!onlyLong.matches("v"));
    assert(!onlyLong.matches("-"));
    assert(!onlyLong.matches(null));
}

unittest {
    auto onlyShort = new Flag("v", null, "d");
    assert(onlyShort.matches("-v"));
    assert(onlyShort.matches("v"));
    assert(!onlyShort.matches("--v"));
    assert(!onlyShort.matches("-x"));
    assert(!onlyShort.matches("verbose"));
    assert(!onlyShort.matches(null));
}

unittest {
    auto a = new Flag("v", "verbose", "one");
    auto b = new Flag("v", "verbose", "two");
    auto c = new Flag("v", null, "one");
    auto d = new Flag(null, "verbose", "one");

    assert(a == a);
    assert(a == b);
    assert(a.toHash() == b.toHash());
    assert(a != c);
    assert(a != d);
    assert(c != d);
    assert(!a.opEquals(new Object()));
}

unittest {
    auto a = new Flag("v", "verbose", "one");
    auto b = new Flag("v", "verbose", "two");
    auto c = new Flag("q", "quiet", "one");

    uint[Flag] counts;
    counts[a] = 2;
    assert(counts[b] == 2);
    assert(c !in counts);
    counts[b] = 5;
    assert(counts.length == 1);
    assert(counts[a] == 5);
}
