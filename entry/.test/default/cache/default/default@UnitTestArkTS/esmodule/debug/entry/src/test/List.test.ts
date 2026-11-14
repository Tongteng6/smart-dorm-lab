import localUnitTest from "@normalized:N&&&entry/src/test/LocalUnit.test&";
import ruleEngineTest from "@normalized:N&&&entry/src/test/RuleEngine.test&";
export default function testsuite() {
    localUnitTest();
    ruleEngineTest();
}
