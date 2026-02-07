let cfg = {};
let drag = false;
let panel = false;
let hide = new Set();
let ch = 0;
let dept = "police";

let prev = [];
let pch = -1;
let nid = -1;
let map = new Map();

function cmp(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
}

$(document).ready(function () {
    $("#officers-list").draggable({
        distance: 5,
        scroll: false,
        appendTo: 'body',
        start: function () {
            drag = true;
            $(this).addClass('ui-draggable-dragging');
        },
        stop: function (event, ui) {
            drag = false;
            $(this).removeClass('ui-draggable-dragging');
            let t = ui.position.top;
            let l = ui.position.left;
            $.post(`https://${GetParentResourceName()}/savePosition`, JSON.stringify({ x: l, y: t }));
        }
    });

    window.addEventListener('message', function (event) {
        const d = event.data;
        if (d.action === "hideList") {
            $("#officers-list").fadeOut(200);
            panel = false;
            return;
        }
        if (d.action === "updateList") {
            cfg = d.config;
            ch = d.localChannel || 0;
            dept = d.deptId || "police";
            const did = dept;

            if (d.units) {
                if (!cmp(d.units, prev) || ch !== pch) {
                    prev = d.units;
                    pch = ch;
                    nid = d.localSource || -1;
                    render(d.units);
                }
            }
            if (d.totalUnits !== undefined) $("#total-units").text(d.totalUnits);

            const dc = d.config?.Departments?.[did] || {};

            if (did === "ambulance") {
                $("#list-title-text").text("ACTIVE MEDICAL UNITS");
                $("#terminal-title-text").text("MEDICAL TERMINAL");
                $("#list-title-icon").attr("class", "fas fa-pulse");
                $("#terminal-title-icon-container i").attr("class", "fas fa-user-md");
            } else {
                $("#list-title-text").text(d.config?.Text?.title || "ACTIVE OFFICERS");
                $("#terminal-title-text").text(d.config?.Text?.settings_title || "OFFICER TERMINAL");
                $("#list-title-icon").attr("class", "fas fa-satellite-dish");
                $("#terminal-title-icon-container i").attr("class", "fas fa-shield-alt");
            }

            if (d.onDuty !== undefined) {
                const $badge = $("#duty-status-badge");
                if (d.onDuty) {
                    $badge.text("ON DUTY").addClass("online");
                    $("#toggle-duty-btn span").text("GO OFF DUTY");
                } else {
                    $badge.text("OFF DUTY").removeClass("online");
                    $("#toggle-duty-btn span").text("GO ON DUTY");
                }
            }

            if (d.config) {
                $(".tablet-status").html(`<i class="fas fa-circle-notch fa-spin"></i> ${d.config.Text.tablet_status}`);
                $(".tablet-footer p").text(d.config.Text.tablet_footer);
                $("#callsign-input").attr("placeholder", d.config.Text.input_placeholder || "CALLSIGN");

                const theme = d.config.Themes[d.config.Theme || "Neutral"] || d.config.Themes["Neutral"];

                let primary = theme.PrimaryColor;
                if (did === "ambulance") {
                    primary = "#ef4444";
                    document.documentElement.style.setProperty('--danger', primary);
                } else {
                    document.documentElement.style.setProperty('--danger', "#ef4444");
                }

                function hex2rgb(h) {
                    const r = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(h);
                    return r ? `${parseInt(r[1], 16)}, ${parseInt(r[2], 16)}, ${parseInt(r[3], 16)}` : null;
                }

                const prgb = hex2rgb(primary) || "38, 115, 235";
                const dc = getComputedStyle(document.documentElement).getPropertyValue('--danger').trim() || "#ef4444";
                const drgb = hex2rgb(dc) || "239, 68, 68";

                document.documentElement.style.setProperty('--primary', primary);
                document.documentElement.style.setProperty('--primary-rgb', prgb);
                document.documentElement.style.setProperty('--danger-rgb', drgb);
                document.documentElement.style.setProperty('--bg-rgb', theme.MainBackground);
                document.documentElement.style.setProperty('--bg-header', theme.HeaderBackground);
                document.documentElement.style.setProperty('--row-hover', theme.RowBackground);
                document.documentElement.style.setProperty('--dept-bg', theme.SubheaderBackground);
                document.documentElement.style.setProperty('--border-color', theme.BorderColor);
                document.documentElement.style.setProperty('--text-main', theme.TextColor);
                document.documentElement.style.setProperty('--text-sec', theme.TextSecondary);
                document.documentElement.style.setProperty('--talking-glow', d.config.UI.TalkingColor);
                document.documentElement.style.setProperty('--border', `1px solid ${theme.BorderColor}`);
                document.documentElement.style.setProperty('--hud-bg', d.config.Theme === "Bright" ? '#f8fafc' : `rgba(${theme.MainBackground}, var(--hud-alpha))`);
                document.documentElement.style.setProperty('--gaming-bg', d.config.Theme === "Bright" ? '#f8fafc' : `rgba(${theme.MainBackground}, 0.98)`);
                document.documentElement.style.setProperty('--gaming-card-bg', d.config.Theme === "Bright" ? 'rgba(0, 0, 0, 0.05)' : 'rgba(255, 255, 255, 0.05)');

                const cj = dc.joinBtnColor || d.config.UI.JoinButtonColor;
                if (cj && cj !== "") {
                    document.documentElement.style.setProperty('--join-btn-bg', cj);
                    document.documentElement.style.setProperty('--join-btn-text', "#ffffff");
                    document.documentElement.style.setProperty('--join-btn-border', cj);
                } else {
                    document.documentElement.style.setProperty('--join-btn-text', primary);
                    document.documentElement.style.setProperty('--join-btn-bg', `rgba(${prgb}, 0.15)`);
                    document.documentElement.style.setProperty('--join-btn-border', primary);
                }

                if (d.config.AllowRadioJoining === false) {
                    $("#comm-section").hide();
                    $(".gaming-grid").addClass("two-columns");
                } else {
                    $("#comm-section").show();
                    $(".gaming-grid").removeClass("two-columns");
                }

                if (d.config.EnablePanicButton) {
                    $(".panic-btn-wrapper").show();
                } else {
                    $(".panic-btn-wrapper").hide();
                }

            }

            if (d.visible !== undefined) {
                panel = d.visible;
                const $list = $("#officers-list");
                if (panel) { if (!$list.is(":visible")) $list.fadeIn(200); $("#toggle-list-btn span").text("HIDE LIST"); }
                else { if ($list.is(":visible")) $list.fadeOut(200); $("#toggle-list-btn span").text("SHOW LIST"); }
            }

            if (d.pos && !drag) $("#officers-list").css({ top: d.pos.y, left: d.pos.x });
            if (d.opacity !== undefined) {
                document.documentElement.style.setProperty('--hud-alpha', d.opacity);
                if (!$("#opacity-slider").is(":focus")) {
                    $("#opacity-slider").val(d.opacity);
                    $("#opacity-val").text(Math.round(d.opacity * 100) + "%");
                    const ha = 0.3 + (d.opacity * 0.7);
                    document.documentElement.style.setProperty('--header-alpha', ha.toFixed(2));
                }
            }
            if (d.scale !== undefined) {
                $("#officers-list").css({ "transform": "none", "zoom": d.scale });
                $("#scale-slider").val(d.scale);
                $("#scale-val").text(d.scale + "x");
            }
        } else if (d.action === "setTalking") {
            const cached = map.get(parseInt(d.source));
            if (!cached) return;
            if (cached.gid === ch && d.talking) cached.pill.addClass("radio-talking");
            else cached.pill.removeClass("radio-talking");
        } else if (d.action === "updateLocalChannel") {
            ch = d.channel || 0;
            $(".radio-talking").removeClass("radio-talking");
        } else if (d.action === "openSettings") {
            cfg = d.config;
            dept = d.deptId || "police";
            panel = true;
            $("#settings-panel").fadeIn(200);
            $("body").addClass("settings-open");
            $("#callsign-input").val(d.currentCallsign);

            if (d.onDuty !== undefined) {
                const $badge = $("#duty-status-badge");
                if (d.onDuty) {
                    $badge.text("ON DUTY").addClass("online");
                    $("#toggle-duty-btn span").text("GO OFF DUTY");
                } else {
                    $badge.text("OFF DUTY").removeClass("online");
                    $("#toggle-duty-btn span").text("GO ON DUTY");
                }
            }
            if (d.localSource !== undefined) nid = d.localSource;
            buildCh();
        } else if (d.action === "closeSettings") {
            panel = false;
            $("#settings-panel").fadeOut(200);
            $("body").removeClass("settings-open");
        }
    });

    $(document).on('keydown', function (e) { if (e.key === "Escape") { $.post(`https://${GetParentResourceName()}/closeUI`); $("#settings-panel").fadeOut(200); $("body").removeClass("settings-open"); } });
    $("#close-settings-btn").click(function () { $.post(`https://${GetParentResourceName()}/closeUI`); $("#settings-panel").fadeOut(200); $("body").removeClass("settings-open"); });
    $("#save-callsign-btn").click(function () { $.post(`https://${GetParentResourceName()}/saveCallsign`, JSON.stringify({ callsign: $("#callsign-input").val() })); });
    $("#panic-btn-small").click(function () {
        $.post(`https://${GetParentResourceName()}/triggerPanic`);
    });

    $("#toggle-list-btn").click(function () {
        panel = !panel;
        if (panel) { $("#officers-list").fadeIn(200); $("#toggle-list-btn span").text("HIDE LIST"); }
        else { $("#officers-list").fadeOut(200); $("#toggle-list-btn span").text("SHOW LIST"); }
        $.post(`https://${GetParentResourceName()}/toggleList`, JSON.stringify({ visible: panel }));
    });

    function buildCh() {
        const list = $("#radio-selection-list");
        list.find(".radio-select-item").remove();

        if (cfg && cfg.DepartmentRadioChannels) {
            const depts = cfg.DepartmentRadioChannels[dept] || {};
            list.append(`<div class="radio-select-item" data-id="0" data-label="radio off"><i class="fas fa-ban" style="color: #3f3f3f"></i><span>RADIO OFF (0)</span></div>`);

            const sorted = Object.keys(depts).sort((a, b) => parseFloat(a) - parseFloat(b));

            sorted.forEach(id => {
                const c = depts[id];
                if (!c) return;
                list.append(`<div class="radio-select-item" data-id="${id}" data-label="${c.label.toLowerCase()}"><i class="fas ${c.icon || 'fa-walkie-talkie'}" style="color: ${c.color}"></i><span>${c.label} (${id})</span></div>`);
            });
        }
    }

    $("#radio-search-input").on('input', function () {
        const query = $(this).val().toLowerCase();
        $(".radio-select-item").each(function () {
            const l = $(this).attr('data-label');
            const id = $(this).attr('data-id');
            if (l.includes(query) || id.includes(query)) $(this).show(); else $(this).hide();
        });
    });

    $(document).on('click', '.radio-select-item', function () {
        const id = $(this).attr('data-id');
        $.post(`https://${GetParentResourceName()}/joinRadio`, JSON.stringify({ channel: id }));
    });

    $(document).on('click', '.dept-subheader', function (e) {
        const isJoin = $(e.target).closest('.dept-join-btn').length > 0;
        const cid = parseInt($(this).attr('data-id'));
        if (isNaN(cid)) return;
        if (isJoin) $.post(`https://${GetParentResourceName()}/joinRadio`, JSON.stringify({ channel: cid }));
        else {
            if (hide.has(cid)) hide.delete(cid); else hide.add(cid);
            $(this).next(".officers-sublist").stop(true, true).slideToggle(200);
            const $icon = $(this).find(".collapse-icon");
            if (hide.has(cid)) $icon.removeClass("fa-chevron-down").addClass("fa-chevron-right");
            else $icon.removeClass("fa-chevron-right").addClass("fa-chevron-down");
        }
    });

    let ot;
    $("#opacity-slider").on('input', function () {
        const v = $(this).val();
        $("#opacity-val").text(Math.round(v * 100) + "%");
        document.documentElement.style.setProperty('--hud-alpha', v);
        const ha = 0.3 + (v * 0.7);
        document.documentElement.style.setProperty('--header-alpha', ha.toFixed(2));

        clearTimeout(ot);
        ot = setTimeout(() => {
            $.post(`https://${GetParentResourceName()}/updateOpacity`, JSON.stringify({ opacity: v }));
        }, 200);
    });

    $("#scale-slider").on('input', function () {
        const v = $(this).val();
        $("#scale-val").text(v + "x");
        $("#officers-list").css({ "transform": "none", "zoom": v });
        $.post(`https://${GetParentResourceName()}/updateScale`, JSON.stringify({ scale: v }));
    });

    $("#toggle-duty-btn").click(function () {
        $.post(`https://${GetParentResourceName()}/toggleDuty`);
    });

    $("#reset-position-btn").click(function () {
        const def = { top: 400, left: 20 };
        $("#officers-list").css(def);
        $.post(`https://${GetParentResourceName()}/savePosition`, JSON.stringify({ x: def.left, y: def.top }));
    });

    $(document).on('click', '.list-header', function () { $.post(`https://${GetParentResourceName()}/openActiveOfficersSettings`); });
    $(document).on('click', '.officer-row', function () {
        const src = $(this).attr('data-source');
        if (src) $.post(`https://${GetParentResourceName()}/setWaypoint`, JSON.stringify({ source: parseInt(src) }));
    });
});

function render(units) {
    const container = $("#departments-content").empty();
    map.clear();

    const panics = [];
    units.forEach(g => {
        g.units = g.units.filter(u => {
            if (u.isPanic) { panics.push({ ...u, originalGroup: g }); return false; }
            return true;
        });
    });

    if (panics.length > 0) {
        draw({ id: 99999, label: "PANIC ALERT", color: "#ef4444", icon: "fa-triangle-exclamation", units: panics }, true);
    }

    units.forEach(g => {
        if (g.units.length === 0) return;
        const isC = hide.has(g.id);
        draw(g, false, isC);
    });

    function draw(g, isP, isC = false) {
        const jBtn = (cfg && cfg.AllowRadioJoining !== false && !isP) ? `<div class="dept-join-btn">${cfg.Text.join_btn}</div>` : '';
        const $dBlock = $(`<div class="dept-block"><div class="dept-subheader" data-id="${g.id}"><div class="dept-name-wrapper"><i class="fas ${isC ? 'fa-chevron-right' : 'fa-chevron-down'} collapse-icon"></i><i class="fas ${g.icon || 'fa-walkie-talkie'} dept-channel-icon"></i><span class="dept-name">${g.label}</span><span class="dept-divider">|</span><span class="dept-num-pill">${g.units.length}</span></div>${jBtn}</div><div class="officers-sublist" style="${isC ? 'display: none;' : ''}"></div></div>`);

        const $list = $dBlock.find(".officers-sublist");
        g.units.forEach(u => {
            const isT = (u.talking && (isP ? u.originalGroup?.id : g.id) === ch) ? "radio-talking" : "";
            const isL = u.source == nid;
            const hasC = u.callsign && u.callsign !== "N/A";
            const showR = (cfg && cfg.ShowOfficerRank !== false);
            const isPan = u.isPanic ? "panic-active" : "";
            const $row = $(`<div class="officer-row ${isL ? 'local-player-highlight' : ''} ${isPan}" data-source="${u.source}"><div class="off-badge ${hasC ? '' : 'no-callsign-badge'}" style="${hasC ? 'background:' + u.callsignColor : ''}">${hasC ? u.callsign : 'NO CALL'}</div><div class="off-name">${u.name}</div>${showR ? `<div class="off-rank">${u.rank}</div>` : ''}<div class="off-radio-pill ${isT}" data-source="${u.source}">${u.radioLabel}</div></div>`);

            map.set(parseInt(u.source), {
                pill: $row.find('.off-radio-pill'),
                gid: (isP ? u.originalGroup?.id : g.id)
            });

            $list.append($row);
        });
        container.append($dBlock);
    }
}
