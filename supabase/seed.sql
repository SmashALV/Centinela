-- SOLO desarrollo local. Nunca aplicar este seed a staging o producción.
insert into centinela_private.rubric_versions(version, narrative_version, active, development_only)
values ('TEST_ONLY_P4_v1', 'provisional-d0-1', true, true);

insert into centinela_private.rubric_requirements(rubric_version, dimension, required_items)
values ('TEST_ONLY_P4_v1', 'D1', 1), ('TEST_ONLY_P4_v1', 'D2', 1),
       ('TEST_ONLY_P4_v1', 'D3', 1), ('TEST_ONLY_P4_v1', 'D4', 1);

insert into centinela_private.rubric_items
  (rubric_version, decision_id, choice_id, dimension, points)
values
  ('TEST_ONLY_P4_v1', 'TEST_ONLY_D1', 'TEST_ONLY_SAFE', 'D1', 2),
  ('TEST_ONLY_P4_v1', 'TEST_ONLY_D1', 'TEST_ONLY_OTHER', 'D1', 0),
  ('TEST_ONLY_P4_v1', 'TEST_ONLY_D2', 'TEST_ONLY_SAFE', 'D2', 2),
  ('TEST_ONLY_P4_v1', 'TEST_ONLY_D2', 'TEST_ONLY_OTHER', 'D2', 0),
  ('TEST_ONLY_P4_v1', 'TEST_ONLY_D3', 'TEST_ONLY_SAFE', 'D3', 2),
  ('TEST_ONLY_P4_v1', 'TEST_ONLY_D3', 'TEST_ONLY_OTHER', 'D3', 0),
  ('TEST_ONLY_P4_v1', 'TEST_ONLY_D4', 'TEST_ONLY_SAFE', 'D4', 2),
  ('TEST_ONLY_P4_v1', 'TEST_ONLY_D4', 'TEST_ONLY_OTHER', 'D4', 0);
