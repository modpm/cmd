module cmd.flag_test;

import core.exception : AssertError;

import fluent.asserts;

import cmd.flag;

unittest {
    expect({ new Flag(null, null, "d"); }).to.throwException!AssertError;
    expect({ new Flag("ab", "verbose", "d"); }).to.throwException!AssertError;
    expect({ new Flag("", "verbose", "d"); }).to.throwException!AssertError;
    expect({ new Flag("v", "", "d"); }).to.throwException!AssertError;
    expect({ new Flag(null, "", "d"); }).to.throwException!AssertError;
}

unittest {
    auto flag = Flag.fromString("-v, --verbose", "Verbose output");
    expect(flag.shortName).to.equal("v");
    expect(flag.longName).to.equal("verbose");
    expect(flag.description).to.equal("Verbose output");
}

unittest {
    auto onlyLong = Flag.fromString("--verbose", "d");
    expect(onlyLong.shortName).to.beNull;
    expect(onlyLong.longName).to.equal("verbose");

    auto onlyShort = Flag.fromString("-v", "d");
    expect(onlyShort.shortName).to.equal("v");
    expect(onlyShort.longName).to.beNull;
}

unittest {
    foreach (format; ["--verbose, -v", "-v,--verbose", "  -v ,  --verbose  ", "  --verbose,-v  "]) {
        auto flag = Flag.fromString(format, "d");
        expect(flag.shortName).to.equal("v");
        expect(flag.longName).to.equal("verbose");
    }
}

unittest {
    expect({ Flag.fromString("-a, -b, --c", "d"); }).to.throwException!AssertError;
    expect({ Flag.fromString("-a,-b,-c,-d", "d"); }).to.throwException!AssertError;
}

unittest {
    auto both = new Flag("v", "verbose", "d");
    expect(both.formattedName()).to.equal("-v, --verbose");
    expect(both.formattedName(true)).to.equal("-v, --verbose");
    expect(both.formattedName(false)).to.equal("-v, --verbose");
}

unittest {
    auto onlyShort = new Flag("v", null, "d");
    expect(onlyShort.formattedName()).to.equal("-v");
    expect(onlyShort.formattedName(true)).to.equal("-v");
}

unittest {
    auto onlyLong = new Flag(null, "verbose", "d");
    expect(onlyLong.formattedName()).to.equal("--verbose");
    expect(onlyLong.formattedName(false)).to.equal("--verbose");
    expect(onlyLong.formattedName(true)).to.equal("    --verbose");
}

unittest {
    auto flag = new Flag("v", "verbose", "d");
    expect(flag.matches("--verbose")).to.equal(true);
    expect(flag.matches("-v")).to.equal(true);
    expect(flag.matches("verbose")).to.equal(true);
    expect(flag.matches("v")).to.equal(true);
}

unittest {
    auto flag = new Flag("v", "verbose", "d");
    expect(flag.matches("--v")).to.equal(false);
    expect(flag.matches("-verbose")).to.equal(false);
    expect(flag.matches("--x")).to.equal(false);
    expect(flag.matches("-x")).to.equal(false);
    expect(flag.matches("x")).to.equal(false);
    expect(flag.matches("--")).to.equal(false);
    expect(flag.matches("-")).to.equal(false);
    expect(flag.matches("")).to.equal(false);
    expect(flag.matches(null)).to.equal(false);
}

unittest {
    auto onlyLong = new Flag(null, "verbose", "d");
    expect(onlyLong.matches("--verbose")).to.equal(true);
    expect(onlyLong.matches("verbose")).to.equal(true);
    expect(onlyLong.matches("-v")).to.equal(false);
    expect(onlyLong.matches("v")).to.equal(false);
    expect(onlyLong.matches("-")).to.equal(false);
    expect(onlyLong.matches(null)).to.equal(false);
}

unittest {
    auto onlyShort = new Flag("v", null, "d");
    expect(onlyShort.matches("-v")).to.equal(true);
    expect(onlyShort.matches("v")).to.equal(true);
    expect(onlyShort.matches("--v")).to.equal(false);
    expect(onlyShort.matches("-x")).to.equal(false);
    expect(onlyShort.matches("verbose")).to.equal(false);
    expect(onlyShort.matches(null)).to.equal(false);
}

unittest {
    auto a = new Flag("v", "verbose", "one");
    auto b = new Flag("v", "verbose", "two");
    auto c = new Flag("v", null, "one");
    auto d = new Flag(null, "verbose", "one");

    expect(a).to.equal(a);
    expect(a).to.equal(b);
    expect(a.toHash()).to.equal(b.toHash());
    expect(a).to.not.equal(c);
    expect(a).to.not.equal(d);
    expect(c).to.not.equal(d);
    expect(a.opEquals(new Object())).to.equal(false);
}

unittest {
    auto a = new Flag("v", "verbose", "one");
    auto b = new Flag("v", "verbose", "two");
    auto c = new Flag("q", "quiet", "one");

    uint[Flag] counts;
    counts[a] = 2;
    expect(counts[b]).to.equal(2);
    expect(c in counts).to.beNull;
    counts[b] = 5;
    expect(counts.length).to.equal(1);
    expect(counts[a]).to.equal(5);
}
