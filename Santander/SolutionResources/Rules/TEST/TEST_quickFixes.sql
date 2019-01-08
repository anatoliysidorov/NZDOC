DECLARE
  v_finalreport           NCLOB;
  v_caseworkersreport     NCLOB;
  v_externalpartiesreport NCLOB;
  v_brreport              NCLOB;
  v_teamsreport           NCLOB;
  v_skillsreport          NCLOB;
  v_unusedreport          NCLOB;
  v_res                   NUMBER;
BEGIN
  v_finalreport           := NULL;
  v_caseworkersreport     := NULL;
  v_externalpartiesreport := NULL;
  v_brreport              := NULL;
  v_teamsreport           := NULL;
  v_skillsreport          := NULL;
  v_unusedreport          := NULL;

  v_res := f_test_fixcaseworkers(Report => v_caseworkersreport);
  IF v_caseworkersreport IS NOT NULL THEN
    v_finalreport := '<br><b>Caseworkers Fix:</b>' || v_caseworkersreport;
  END IF;

  v_res := f_test_fixexternalparties(Report => v_externalpartiesreport);
  IF v_externalpartiesreport IS NOT NULL THEN
    v_finalreport := v_finalreport || '<br><b>External Parties Fix:</b>' || v_externalpartiesreport;
  END IF;

  v_res := f_test_fixbroles(Report => v_brreport);
  IF v_brreport IS NOT NULL THEN
    v_finalreport := v_finalreport || '<br><b>Business Roles Fix:</b>' || v_brreport;
  END IF;

  v_res := f_test_fixteams(Report => v_teamsreport);
  IF v_teamsreport IS NOT NULL THEN
    v_finalreport := v_finalreport || '<br><b>Teams Fix:</b>' || v_teamsreport;
  END IF;

  v_res := f_test_fixskills(Report => v_skillsreport);
  IF v_skillsreport IS NOT NULL THEN
    v_finalreport := v_finalreport || '<br><b>Skills Fix:</b>' || v_skillsreport;
  END IF;

  v_res := f_test_fixunuseditems(Report => v_unusedreport);
  IF v_unusedreport IS NOT NULL THEN
    v_finalreport := v_finalreport || '<br><b>Unused Items Fix:</b>' || v_unusedreport;
  END IF;

  :Report := nvl(v_finalreport, 'No Fix Needed');
END;
