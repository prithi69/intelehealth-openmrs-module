package org.openmrs.module.intelehealth.page.controller;

import org.apache.commons.lang3.StringUtils;
import org.openmrs.Location;
import org.openmrs.Patient;
import org.openmrs.api.EncounterService;
import org.openmrs.api.VisitService;
import org.openmrs.api.context.Context;
import org.openmrs.module.appframework.context.AppContextModel;
import org.openmrs.module.appframework.domain.AppDescriptor;
import org.openmrs.module.appframework.domain.Extension;
import org.openmrs.module.appframework.service.AppFrameworkService;
import org.openmrs.module.appui.UiSessionContext;
import org.openmrs.module.coreapps.CoreAppsConstants;
import org.openmrs.module.coreapps.CoreAppsProperties;
import org.openmrs.module.coreapps.contextmodel.PatientContextModel;
import org.openmrs.module.coreapps.contextmodel.VisitContextModel;
import org.openmrs.module.emrapi.EmrApiProperties;
import org.openmrs.module.emrapi.adt.AdtService;
import org.openmrs.module.emrapi.event.ApplicationEventService;
import org.openmrs.module.emrapi.patient.PatientDomainWrapper;
import org.openmrs.module.emrapi.visit.VisitDomainWrapper;
import org.openmrs.ui.framework.annotation.InjectBeans;
import org.openmrs.ui.framework.annotation.SpringBean;
import org.openmrs.ui.framework.page.PageModel;
import org.openmrs.ui.framework.page.Redirect;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class IntelehealthPatientDashboardPageController {

    public Object controller(@RequestParam("patientId") Patient patient, PageModel model,
                             @RequestParam(required = false, value = "app") AppDescriptor app,
                             @RequestParam(required = false, value = "dashboard") String dashboard,
                             @InjectBeans PatientDomainWrapper patientDomainWrapper,
                             @SpringBean("adtService") AdtService adtService,
                             @SpringBean("visitService") VisitService visitService,
                             @SpringBean("encounterService") EncounterService encounterService,
                             @SpringBean("emrApiProperties") EmrApiProperties emrApiProperties,
                             @SpringBean("appFrameworkService") AppFrameworkService appFrameworkService,
                             @SpringBean("applicationEventService") ApplicationEventService applicationEventService,
                             @SpringBean("coreAppsProperties") CoreAppsProperties coreAppsProperties,
                             UiSessionContext sessionContext) {

        if (!Context.hasPrivilege(CoreAppsConstants.PRIVILEGE_PATIENT_DASHBOARD)) {
            return new Redirect("coreapps", "noAccess", "");
        }
        else if (patient.isVoided() || patient.isPersonVoided()) {
            return new Redirect("coreapps", "patientdashboard/deletedPatient", "patientId=" + patient.getId());
        }

        if (StringUtils.isEmpty(dashboard)) {
            dashboard = "patientDashboard";
        }

        patientDomainWrapper.setPatient(patient);
        model.addAttribute("patient", patientDomainWrapper);
        model.addAttribute("app", app);

        Location visitLocation = null;
        try {
            visitLocation = adtService.getLocationThatSupportsVisits(sessionContext.getSessionLocation());
        }
        catch (IllegalArgumentException ex) {
            // location does not support visits
        }

        VisitDomainWrapper activeVisit = null;
        if (visitLocation != null) {
            activeVisit = adtService.getActiveVisit(patient, visitLocation);
        }
        model.addAttribute("activeVisit", activeVisit);

        AppContextModel contextModel = sessionContext.generateAppContextModel();
        contextModel.put("patient", new PatientContextModel(patient));
        contextModel.put("visit", activeVisit == null ? null : new VisitContextModel(activeVisit));
        model.addAttribute("appContextModel", contextModel);

        List<Extension> overallActions = appFrameworkService.getExtensionsForCurrentUser(dashboard + ".overallActions", contextModel);
        Collections.sort(overallActions);
        model.addAttribute("overallActions", overallActions);

        List<Extension> visitActions;
        if (activeVisit == null) {
            visitActions = new ArrayList<Extension>();
        } else {
            visitActions = appFrameworkService.getExtensionsForCurrentUser(dashboard + ".visitActions", contextModel);
            Collections.sort(visitActions);
        }
        model.addAttribute("visitActions", visitActions);

        List<Extension> includeFragments = appFrameworkService.getExtensionsForCurrentUser(dashboard + ".includeFragments");
        Collections.sort(includeFragments);
        model.addAttribute("includeFragments", includeFragments);

        List<Extension> firstColumnFragments = appFrameworkService.getExtensionsForCurrentUser(dashboard + ".firstColumnFragments");
        Collections.sort(firstColumnFragments);
        model.addAttribute("firstColumnFragments", firstColumnFragments);

        List<Extension> secondColumnFragments = appFrameworkService.getExtensionsForCurrentUser(dashboard + ".secondColumnFragments");
        Collections.sort(secondColumnFragments);
        model.addAttribute("secondColumnFragments", secondColumnFragments);

        List<Extension> otherActions = appFrameworkService.getExtensionsForCurrentUser(
                (dashboard == "patientDashboard" ? "clinicianFacingPatientDashboard" : dashboard) + ".otherActions", contextModel);
        Collections.sort(otherActions);
        model.addAttribute("otherActions", otherActions);

        model.addAttribute("dashboardUrl", "/coreapps/clinicianfacing/patient.page?patientId="+ patient.getId() + "&dashboard=" + dashboard);

        applicationEventService.patientViewed(patient, sessionContext.getCurrentUser());

        return null;
    }

}