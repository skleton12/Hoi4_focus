"""Generator regressions; these do not replace HOI4 runtime testing."""
import importlib.util
import json
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'design/generic_tree'))
import build_mod as build

spec = importlib.util.spec_from_file_location('mod_validator', ROOT / 'tools/validate.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class FocusEffectsTest(unittest.TestCase):
    def test_consumer_goods_first_application_and_refresh(self):
        text = ' '.join(build.rewards('소비재 공장 -5%'))
        self.assertIn('value = -0.05', text)
        initial = text.index('set_variable = { var = GJ_consumer_goods_factor value = 0 }')
        addition = text.index('add_to_variable = { var = GJ_consumer_goods_factor')
        attachment = text.index('add_dynamic_modifier = { modifier = GJ_reform_industry }')
        refresh = text.index('force_update_dynamic_modifier = yes')
        self.assertLess(initial, addition)
        self.assertLess(addition, attachment)
        self.assertLess(attachment, refresh)
        entries = validator.parse(validator.tokenize(text))
        hidden = entries[0].value
        # Initial values must never overwrite earlier focus rewards.
        for entry in hidden:
            if entry.key != 'if':
                continue
            setters = [e for e in entry.value if e.key == 'set_variable']
            for setter in setters:
                variable = validator.scalar(setter.value, 'var')
                limit = validator.children(entry.value, 'limit')[0]
                self.assertEqual(validator.scalar(validator.children(limit.value, 'NOT')[0].value,
                                                  'has_variable'), variable)

    def test_previously_tooltip_only_modifiers(self):
        cases = [
            ('사단 증원 속도 +15%', 'land_reinforce_rate', '0.15'),
            ('사단 이동 속도 +5%', 'army_speed_factor', '0.05'),
            ('사단 경험 획득 +10%', 'experience_gain_army_unit_factor', '0.1'),
            ('사단 훈련 시간 -10%', 'training_time_army_factor', '-0.1'),
            ('근접 지원 효율 +5%', 'air_cas_efficiency', '0.05'),
            ('특수부대 대대 한도 +2', 'special_forces_cap_flat', '2'),
            ('의용군 파견 한도 +1', 'send_volunteer_size', '1'),
        ]
        definitions = build.dynamic_modifier_file()
        for description, modifier, value in cases:
            with self.subTest(effect=description):
                script = ' '.join(build.rewards(description))
                self.assertIn(f'add_to_variable = {{ var = GJ_{modifier} value = {value} }}', script)
                self.assertIn(f'{modifier} = GJ_{modifier}', definitions)
                self.assertNotIn('준비 중', build.tooltip(description))

    def test_repeated_modifier_fragments_are_not_dropped(self):
        text = ' '.join(build.rewards('소비재 공장 -3%, 소비재 공장 -2%'))
        self.assertIn('value = -0.03', text)
        self.assertIn('value = -0.02', text)
        self.assertEqual(text.count('force_update_dynamic_modifier = yes'), 1)

    def test_immediate_rewards_are_preserved(self):
        self.assertEqual(build.rewards('정치력 +25'), ['add_political_power = 25'])
        self.assertEqual(build.rewards('공군 경험 +25'), ['air_experience = 25'])
        self.assertEqual(build.rewards('안정도 -3%'), ['add_stability = -0.03'])

    def test_tooltip_is_explicit_and_colored(self):
        self.assertIn('§G-5%§!', build.tooltip('소비재 공장 -5%'))
        self.assertIn('§G-10%§!', build.tooltip('사단 훈련 시간 -10%'))
        self.assertEqual(build.rewards('평화 협상 디시전 해금'), [])
        self.assertIn('(준비 중)', build.tooltip('평화 협상 디시전 해금'))
        self.assertNotIn('설계 효과:', build.tooltip('소비재 공장 -5%'))

    def test_every_dynamic_reward_has_a_refresh_and_defined_variables(self):
        definitions = build.dynamic_modifier_file()
        checked = 0
        for path in build.DATA.glob('*.json'):
            for group in json.loads(path.read_text(encoding='utf-8'))['groups']:
                for focus in group['focuses']:
                    script = ' '.join(build.rewards(focus['effect']))
                    variables = re.findall(r'add_to_variable = \{ var = (GJ_\w+)', script)
                    if not variables:
                        continue
                    checked += 1
                    self.assertIn('force_update_dynamic_modifier = yes', script)
                    for variable in variables:
                        self.assertIn(f'= {variable}\n', definitions)
                    validator.parse(validator.tokenize(script))
        self.assertGreater(checked, 300)


if __name__ == '__main__':
    unittest.main()
