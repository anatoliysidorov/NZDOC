Ext.define('DCM.view.SearchCases.grid.Panel', {
    extend: 'EcxUtils5.BaseClass.GridView',
    alias: 'widget.SearchCases-grid',

    requires: [
        'DCM.view.SearchCases.grid.ViewModel'
    ],

    viewModel: 'SearchCasesViewModel-grid',

    bind: {
        store: '{storeSearchCases}',
        selection: '{current.Case}'
    },

    reference: 'grdSearchCases', //grid
    //topbar
    dockedItems: [{
        xtype: 'ecx-actiontoolbar',
        reference: 'tlbrCaseActions',
        dock: 'top',
        items: [
            {
                xtype: 'ecx-new-button',
                tooltip: t('New Case', {context: 'action'}),
                handler: 'onActionNew',
                bind: {
                    disabled: '{isDisabledCaseworker}',
                    hidden: '{!isEnable}'
                }
            },
            '->', {
                xtype: 'ecx-exportbutton'
            }, {
                xtype: 'ecx-reload-button'
            }
        ]
    }
    ],
    columns: [{
        width: 5,
        dataIndex: 'CASESYSTYPE_COLORCODE',
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            var casestateInfo = EcxUtils5.DCM.getCaseStateInfo({
                ISSTART: record.get('CASESTATE_ISSTART'),
                ISFINISH: record.get('CASESTATE_ISFINISH')
            });
            metaData.tdCls = ' ' + (casestateInfo.cls || '');
        }
    }, {
        text: 'ID',
        dataIndex: 'ID',
        sortable: true,
        hidden: true,
        width: 50
    }, {
        text: t('T', {context: 'caseType'}),
        dataIndex: 'CASESYSTYPE_NAME',
        width: 45,
        sortable: true,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            metaData.tdAttr = Ext.String.format('title="{0}"', record.get('CASESYSTYPE_NAME'));
            return EcxUtils5.DCM.renderCaseType(null, record.get('CASESYSTYPE_COLORCODE'), record.get('CASESYSTYPE_ICONCODE'));
        }
    }, {
        text: t('Case Type'),
        dataIndex: 'CASESYSTYPE_NAME',
        width: 200,
        sortable: true,
        hidden: true
    }, {
        text: t('Case ID'),
        dataIndex: 'CASEID',
        width: 140,
        sortable: true,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            var c = view.lookupController(),
                isRenderLink = (record.get('PERM_CASETYPE_DETAIL') !== undefined) ? record.get('PERM_CASETYPE_DETAIL') : true;
            return (isRenderLink) ? c.renderDetailLink(value, metaData, record) : value;
        }
    }, {
        text: t('Summary'),
        dataIndex: 'SUMMARY',
        flex: 1,
        sortable: true,
        minWidth: 400
    }, {
        dataIndex: 'GOALSLADURATION',
        text: t('Goal'),
        width: 160,
        hidden: false,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            //only show SLA if case is not closed
            if (record.get('CASESTATE_ISFINISH')) {
                return '';
            }
            var ms,
                slaDuration = '';
            //calculate duration
            if (record.get('GOALSLADURATION') != null) {
                ms = -1 * record.get('GOALSLADURATION');
                slaDuration = EcxUtils5.DCM.renderderSLA(ms);
            }
            return slaDuration;
        }
    }, {
        dataIndex: 'DLINESLADURATION',
        text: t('Deadline'),
        width: 160,
        hidden: false,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            //only show SLA if case is not closed
            if (record.get('CASESTATE_ISFINISH')) {
                return '';
            }
            var ms,
                slaDuration = '';
            //calculate duration
            if (record.get('DLINESLADURATION') != null) {
                ms = -1 * record.get('DLINESLADURATION');
                slaDuration = EcxUtils5.DCM.renderderSLA(ms);
            }
            return slaDuration;
        }
    }, {
        text: t('Case Owner'),
        dataIndex: 'WORKBASKET_NAME',
        width: 200,
        sortable: true,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            return EcxUtils5.DCM.renderWorkBasket(record.get('WORKBASKET_NAME'), record.get('WORKBASKET_TYPE_CODE'));
        },
        bind: {
            hidden: '{isHideCaseOwnerField}'
        }
    }, {
        text: t('P', {context: 'priority'}),
        dataIndex: 'PRIORITY_VALUE',
        width: 40,
        sortable: true,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, r) {
            metaData.tdAttr = Ext.String.format('title="{0} ({1})"', record.get('PRIORITY_NAME'), record.get('PRIORITY_VALUE'));
            return EcxUtils5.DCM.renderPriority(record.get('PRIORITY_VALUE'));
        }
    }, {
        text: t('State'),
        dataIndex: 'CASESTATE_NAME',
        width: 125,
		hidden:true,
        sortable: true,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            var config = {
                ISSTART: record.get('CASESTATE_ISSTART'),
                ISFINISH: record.get('CASESTATE_ISFINISH')
            };
            var casestate = EcxUtils5.DCM.renderCaseState(value, config);
            metaData.tdCls += ' ' + EcxUtils5.DCM.getCaseStateInfo(config).cls + '-bgl';
            return casestate;
        }
    }, {
        text: t('Milestone'),
        dataIndex: 'MS_STATENAME',
        width: 125,
        sortable: true,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            var config = {
                ISSTART: record.get('CASESTATE_ISSTART'),
                ISFINISH: record.get('CASESTATE_ISFINISH')
            };
            var casestate = EcxUtils5.DCM.renderCaseState(value, config);
            metaData.tdCls += ' ' + EcxUtils5.DCM.getCaseStateInfo(config).cls + '-bgl';
            return casestate;
        }
    },  {
        text: t('Resolution'),
        dataIndex: 'RESOLUTIONCODE_NAME',
        width: 150,
        sortable: true,
        renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
            return EcxUtils5.DCM.renderResCode(
                record.get('RESOLUTIONCODE_NAME'),
                record.get('RESOLUTIONCODE_THEME'),
                record.get('RESOLUTIONCODE_ICON'),
                metaData);
        }
    },
        {
            xtype: 'ecx-datecolumn',
            baseField: 'CREATED'
        },
        {
            xtype: 'ecx-namecolumn',
            baseField: 'CREATED'
        },
        {
            xtype: 'ecx-datecolumn',
            baseField: 'MODIFIED',
			hidden: true
        },
        {
            xtype: 'ecx-namecolumn',
            baseField: 'MODIFIED',
			hidden: true
        }
    ]
});
